defmodule PoolV3CheckProfit do
  import Compute
  alias ListDex, as: LD
  alias LogWritter, as: LW
  alias DexSearch, as: DS
  alias TokenContext, as: TC
  alias ProfitableTradeContext, as: PTC
  alias PoolSearch, as: PS
  alias PoolContext, as: PC
  alias PoolV3Context, as: PV3C

  @dexs Libraries.dexs()
  @balancer Libraries.balancer()

  def run(
        %Pool{
          token_pair: %TokenPair{
            decimals_adjuster_0_1: decimals_adjuster_0_1,
            token0: %Token{decimals: decimals0},
            token1: %Token{decimals: decimals1}
          },
          tick_spacing: tick_spacing
        } = pool_event,
        {amount0_delta, amount1_delta, liquidity, sqrtPriceX96, tick} = params
      ) do
    {price_0_1, reserve0, reserve1} =
      PV3C.calculate_price_reserve0_reserve1(
        liquidity,
        sqrtPriceX96,
        tick,
        tick_spacing,
        decimals_adjuster_0_1,
        decimals0,
        decimals1
      )

    {:ok, updated_pool_event} =
      PC.update(
        pool_event,
        %{
          price: price_0_1,
          reserve0: reserve0,
          reserve1: reserve1,
          tick: tick |> Integer.to_string(),
          liquidity: liquidity |> Integer.to_string()
        }
      )

    params |> IO.inspect(label: "mx1 params")

    price_0_1 |> IO.inspect(label: "mx1 price_0_1")
    reserve0 |> IO.inspect(label: "mx1 reserve0")
    reserve1 |> IO.inspect(label: "mx1 reserve1")

    case amount0_delta > 0 do
      true ->
        get_profitable_trade_from_pool(updated_pool_event, %{
          burrow_token: pool_event.token_pair.token0,
          swap_token: pool_event.token_pair.token1,
          swap_amount: amount1_delta * -1,
          swap_direction: "0_1"
        })

      false ->
        get_profitable_trade_from_pool(updated_pool_event, %{
          burrow_token: pool_event.token_pair.token1,
          swap_token: pool_event.token_pair.token0,
          swap_amount: amount0_delta * -1,
          swap_direction: "1_0"
        })
    end
  end

  def get_profitable_trade_from_pool(%Pool{price: "0.0"} = pool_event, _params),
    do: {:error, "pool event with id: #{pool_event.id} price is 0.0"}

  def get_profitable_trade_from_pool(%Pool{price: nil} = pool_event, _params),
    do: {:error, "pool event with id: #{pool_event.id} price is nil"}

  def get_profitable_trade_from_pool(
        %Pool{
          token_pair: %TokenPair{id: token_pair_event_id},
          fee: pool_fee_event,
          price: pool_0_1_event_price
        } = pool_event,
        %{
          burrow_token: %Token{} = borrow_token,
          swap_token: %Token{} = swap_token,
          swap_amount: swap_amount,
          swap_direction: swap_direction
        }
      ) do
    swap_price_event = calculate_price_with_direction(pool_0_1_event_price, swap_direction)

    list_potential_profitable_trades =
      search_profitable_trade(pool_event, swap_amount, swap_price_event, swap_direction)
  end

  def search_profitable_trade(%Pool{} = pool_event, swap_amount, swap_price_event, swap_direction) do
    PS.with_token_pair_id(pool_event.token_pair.id)
    |> PS.with_dex_name("uniswapV3")
    |> Repo.all()
    |> estimate_profitable_pool(pool_event, swap_amount, swap_price_event, swap_direction)
    |> Enum.sort_by(
      fn {_pool_event, _pool_searched, profit_amount, _token_return_symbol, _return_amount,
       _burrow_amount, _token_return_amount_for_gas_fee, _swap_price_event, _swap_direction} -> profit_amount end,
      :desc
    )
  end

  def estimate_profitable_pool(%Pool{} = pool, pool_event, swap_amount, swap_price_event, swap_direction),
    do: estimate_profitable_pool([pool], pool_event, swap_amount, swap_price_event, swap_direction)

  def estimate_profitable_pool([], _, _,  _, _), do: []

  def estimate_profitable_pool(list_pool, pool_event, swap_amount, swap_price_event, swap_direction)
      when is_list(list_pool) do
    list_pool
    |> Enum.filter(fn pool_searched ->
      swap_price_searched = calculate_price_with_direction(pool_searched.price, swap_direction)
      swap_price_searched and swap_price_event > swap_price_searched
    end)
    |> Enum.map(fn pool_searched ->
      {swap_amount_adjusted, return_amount} =
        calculate_swap_and_return_amount_adjusted(pool_searched, swap_amount, swap_direction)

      burrow_amount =
        calculate_burrow_amount(swap_amount_adjusted, swap_price_event, pool_event.fee)

      {token_return_amount_for_gas_fee, token_return_symbol} =
        calculate_gas_price_for_trade_v3(
          extract_token_profit_from_pool(pool_searched, swap_direction)
        )

      profit_amount = return_amount - burrow_amount - token_return_amount_for_gas_fee

      {pool_event, pool_searched, profit_amount, token_return_symbol, return_amount,
       burrow_amount, token_return_amount_for_gas_fee, swap_price_event, swap_direction}
    end)
    |> Enum.filter(fn {_, _, profit_amount, _, _, _, _, _, _} ->
      profit_amount > 0
    end)
  end

  def calculate_price_with_direction("0.0", _), do: nil
  def calculate_price_with_direction(nil, _), do: nil

  def calculate_price_with_direction(pool_price, "0_1"),
    do: pool_price |> String.to_float()

  def calculate_price_with_direction(pool_price, "1_0"),
    do: 1 / (pool_price |> String.to_float())

  def calculate_swap_and_return_amount_adjusted(
        %Pool{} = pool_searched,
        swap_amount_estimated,
        "0_1"
      ) do
    swap_price_0_1_searched = calculate_price_with_direction(pool_searched.price, "0_1")

    return_amount_estimated =
      calculate_return_amount(swap_amount_estimated, swap_price_0_1_searched, pool_searched.fee)

    {swap_amount, return_amount} =
      case return_amount_estimated <= pool_searched.reserve0 do
        true ->
          {swap_amount_estimated, return_amount_estimated}

        false ->
          {pool_searched.reserve0 / swap_amount_estimated * swap_amount_estimated,
           pool_searched.reserve0}
      end
  end

  def calculate_swap_and_return_amount_adjusted(
        %Pool{} = pool_searched,
        swap_amount_estimated,
        "1_0"
      ) do
    swap_price_1_0_searched = calculate_price_with_direction(pool_searched.price, "1_0")

    return_amount_estimated =
      calculate_return_amount(swap_amount_estimated, swap_price_1_0_searched, pool_searched.fee)

    {swap_amount, return_amount} =
      case return_amount_estimated <= pool_searched.reserve1 do
        true ->
          {swap_amount_estimated, return_amount_estimated}

        false ->
          {pool_searched.reserve1 / swap_amount_estimated * swap_amount_estimated,
           pool_searched.reserve1}
      end
  end

  def calculate_return_amount(swap_amount, swap_price_event, pool_fee_event) do
    pool_fee_event_ratio = 1 - (pool_fee_event |> String.to_integer()) / 10000
    swap_amount * swap_price_event * pool_fee_event_ratio
  end

  def calculate_burrow_amount(swap_amount, swap_price_event, pool_fee_event) do
    pool_fee_event_ratio = 1 + (pool_fee_event |> String.to_integer()) / 10000
    swap_amount * swap_price_event * pool_fee_event_ratio
  end

  def extract_token_profit_from_pool(%Pool{} = pool_event, "0_1"),
    do: pool_event.token_pair.token0

  def extract_token_profit_from_pool(%Pool{} = pool_event, "1_0"),
    do: pool_event.token_pair.token1
end
