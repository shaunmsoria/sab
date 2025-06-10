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

    ## TODO remove after testing
    pool_event_address =
      pool_event |> Repo.preload(:pool_address) |> Map.get(:pool_address) |> Map.get(:address)

    {:ok, token0_address} =
      pool(pool_event_address, "uniswapV3", :token0)
      |> LW.ipt("sx1 pool_event_address token0 result")

    {:ok, token1_address} =
      pool(pool_event_address, "uniswapV3", :token1)
      |> LW.ipt("sx1 pool_event_address token1 result")

    ##

    case amount0_delta > 0 do
      true ->
        get_profitable_trade_from_pool(updated_pool_event, %{
          burrow_token: pool_event.token_pair.token0,
          swap_token: pool_event.token_pair.token1,
          swap_amount: amount1_delta * -1,
          swap_direction: "0_1"
        })
        |> IO.inspect(label: "mx1 get_profitable_trade_from_pool")

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
    |> PS.with_dex_abi("uniswapV3")
    |> Repo.all()
    |> estimate_profitable_pool(pool_event, swap_amount, swap_price_event, swap_direction)
    |> Enum.sort_by(
      fn {_pool_event, _pool_searched, profit_amount, _token_return_symbol, _return_amount,
          _burrow_amount, _token_return_amount_for_gas_fee, _swap_price_event, _swap_direction,
          _swap_amount} ->
        profit_amount
      end,
      :desc
    )
  end

  def estimate_profitable_pool(
        %Pool{} = pool,
        pool_event,
        swap_amount,
        swap_price_event,
        swap_direction
      ),
      do:
        estimate_profitable_pool(
          [pool],
          pool_event,
          swap_amount,
          swap_price_event,
          swap_direction
        )

  def estimate_profitable_pool([], _, _, _, _), do: []

  def estimate_profitable_pool(
        list_pool,
        pool_event_raw,
        swap_amount,
        swap_price_event,
        swap_direction
      )
      when is_list(list_pool) do
    pool_event = pool_event_raw |> Repo.preload(token_pair: [:token0, :token1])
    decimals_adjusted = calculate_decimals_adjusted(pool_event, swap_direction)

    list_pool
    |> Enum.filter(fn pool_searched ->
      swap_price_searched = calculate_price_with_direction(pool_searched.price, swap_direction)

      ##
      swap_direction |> LW.ipt("sx1 swap_direction")
      swap_price_event |> LW.ipt("sx1 swap_price_event")
      pool_event.id |> LW.ipt("sx1 pool_event.id")
      swap_price_searched |> LW.ipt("sx1 swap_price_searched")
      pool_searched.id |> LW.ipt("sx1 pool_searched.id")

      (not is_nil(swap_price_searched) and swap_price_event > swap_price_searched)
      |> LW.ipt("sx1 swap_price_event > swap_price_searched")

      ##

      not is_nil(swap_price_searched) and swap_price_event > swap_price_searched
    end)
    |> Enum.map(fn pool_searched_raw ->
      pool_searched = pool_searched_raw |> Repo.preload(token_pair: [:token0, :token1])

      {swap_amount_adjusted, burrow_amount} =
        calculate_swap_and_burrow_amount_adjusted(
          pool_searched,
          swap_amount,
          swap_direction,
          decimals_adjusted
        )

      # {swap_amount_adjusted, return_amount} =
      #   calculate_swap_and_return_amount_adjusted(
      #     pool_event,
      #     swap_amount,
      #     swap_direction,
      #     decimals_adjusted
      #   )

      # {swap_amount_adjusted, return_amount} =
      #   calculate_swap_and_return_amount_adjusted(
      #     pool_searched,
      #     swap_amount,
      #     swap_direction,
      #     decimals_adjusted
      #   )

      swap_price_event = calculate_price_with_direction(pool_event.price, swap_direction)

      return_amount =
        calculate_return_amount(
          swap_amount_adjusted,
          swap_price_event,
          pool_event.fee,
          decimals_adjusted
        )

      # burrow_amount =
      #   calculate_burrow_amount(
      #     swap_amount_adjusted,
      #     swap_price_searched,
      #     pool_searched.fee,
      #     decimals_adjusted
      #   )

      # burrow_amount =
      #   calculate_burrow_amount(
      #     swap_amount_adjusted,
      #     swap_price_event,
      #     pool_searched.fee,
      #     decimals_adjusted
      #   )

      {token_return_amount_for_gas_fee, token_return_symbol} =
        calculate_gas_price_for_trade_v3(
          extract_token_profit_from_pool(pool_event, swap_direction)
        )

      ##
      swap_amount_adjusted |> LW.ipt("sx1 swap_amount_adjusted")
      return_amount |> LW.ipt("sx1 return_amount")
      token_return_symbol |> LW.ipt("sx1 token_return_symbol")
      burrow_amount |> LW.ipt("sx1 burrow_amount")
      token_return_amount_for_gas_fee |> LW.ipt("sx1 token_return_amount_for_gas_fee")
      # profit_amount |> LW.ipt("sx1 profit_amount")
      ##

      profit_amount = return_amount - burrow_amount - token_return_amount_for_gas_fee

      {pool_event, pool_searched, profit_amount, token_return_symbol, return_amount,
       burrow_amount, token_return_amount_for_gas_fee, swap_price_event, swap_direction,
       swap_amount}
    end)
    # |> IO.inspect(label: "mx1 estimate_profitable_pool")
    |> Enum.filter(fn {_, _, profit_amount, _, _, _, _, _, _, _} ->
      profit_amount > 0
    end)
  end

  def calculate_price_with_direction("0.0", _), do: nil
  def calculate_price_with_direction(nil, _), do: nil

  def calculate_price_with_direction(pool_price, direction) when direction in ["0_1", :O_I],
    do: pool_price |> String.to_float()

  def calculate_price_with_direction(pool_price, direction) when direction in ["1_0", :I_O],
    do: 1 / (pool_price |> String.to_float())

  def calculate_swap_and_burrow_amount_adjusted(
        %Pool{} =
          pool,
        swap_amount_estimated,
        "0_1",
        decimals_adjusted
      ) do
    swap_price_0_1 = calculate_price_with_direction(pool.price, "0_1")

    burrow_amount_estimated =
      calculate_burrow_amount(
        swap_amount_estimated,
        swap_price_0_1,
        pool.fee,
        decimals_adjusted
      )

    pool_reserve = pool.reserve0 |> String.to_integer()

    LW.ipt("sx1 calculate_swap_and_burrow_amount_adjusted 0_1")
    swap_amount_estimated |> LW.ipt("sx1 swap_amount_estimated")
    burrow_amount_estimated |> LW.ipt("sx1 burrow_amount_estimated")
    pool.reserve1 |> LW.ipt("sx1 pool.reserve1")
    pool_reserve |> LW.ipt("sx1 pool_reserve")
    pool.id |> LW.ipt("sx1 pool.id")

    {swap_amount, burrown_amount} =
      case burrow_amount_estimated <= pool_reserve do
        true ->
          {swap_amount_estimated, burrow_amount_estimated}

        false ->
          {pool_reserve / burrow_amount_estimated * swap_amount_estimated, pool_reserve}
      end
  end

  def calculate_swap_and_burrow_amount_adjusted(
        %Pool{} = pool,
        swap_amount_estimated,
        "1_0",
        decimals_adjusted
      ) do
    swap_price_1_0 = calculate_price_with_direction(pool.price, "1_0")

    burrow_amount_estimated =
      calculate_burrow_amount(
        swap_amount_estimated,
        swap_price_1_0,
        pool.fee,
        decimals_adjusted
      )

    pool_reserve = pool.reserve1 |> String.to_integer()

    LW.ipt("sx1 calculate_swap_and_burrow_amount_adjusted 1_0")
    burrow_amount_estimated |> LW.ipt("sx1 burrow_amount_estimated")
    pool_reserve |> LW.ipt("sx1 pool_reserve")
    pool.reserve0 |> LW.ipt("sx1 pool.reserve0")
    pool.id |> LW.ipt("sx1 pool.id")

    {swap_amount, burrow_amount} =
      case burrow_amount_estimated <= pool_reserve do
        true ->
          {swap_amount_estimated, burrow_amount_estimated}

        false ->
          {pool_reserve / burrow_amount_estimated * swap_amount_estimated, pool_reserve}
      end
  end

  # def calculate_swap_and_return_amount_adjusted(
  #       %Pool{} =
  #         pool,
  #       swap_amount_estimated,
  #       "0_1",
  #       decimals_adjusted
  #     ) do
  #   swap_price_0_1 = calculate_price_with_direction(pool.price, "0_1")

  #   return_amount_estimated =
  #     calculate_return_amount(
  #       swap_amount_estimated,
  #       swap_price_0_1,
  #       pool.fee,
  #       decimals_adjusted
  #     )

  #   {swap_amount, return_amount} =
  #     case return_amount_estimated <= pool.reserve0 do
  #       true ->
  #         {swap_amount_estimated, return_amount_estimated}

  #       false ->
  #         {pool.reserve0 / swap_amount_estimated * swap_amount_estimated,
  #          pool.reserve0}
  #     end
  # end

  # def calculate_swap_and_return_amount_adjusted(
  #       %Pool{} = pool,
  #       swap_amount_estimated,
  #       "1_0",
  #       decimals_adjusted
  #     ) do
  #   swap_price_1_0_searched = calculate_price_with_direction(pool.price, "1_0")

  #   return_amount_estimated =
  #     calculate_return_amount(
  #       swap_amount_estimated,
  #       swap_price_1_0_searched,
  #       pool.fee,
  #       decimals_adjusted
  #     )

  #   {swap_amount, return_amount} =
  #     case return_amount_estimated <= pool.reserve1 do
  #       true ->
  #         {swap_amount_estimated, return_amount_estimated}

  #       false ->
  #         {pool.reserve1 / swap_amount_estimated * swap_amount_estimated,
  #          pool.reserve1}
  #     end
  # end

  def calculate_return_amount(swap_amount, swap_price, pool_fee, decimals_adjusted) do
    pool_fee_ratio = 1 - (pool_fee |> String.to_integer()) / 10000
    swap_amount * swap_price * pool_fee_ratio * decimals_adjusted
  end

  def calculate_burrow_amount(swap_amount, swap_price, pool_fee, decimals_adjusted) do
    pool_fee_ratio = 1 + (pool_fee |> String.to_integer()) / 10000
    swap_amount * swap_price * pool_fee_ratio * decimals_adjusted
  end

  def extract_token_profit_from_pool(%Pool{} = pool, "0_1"),
    do: pool.token_pair.token0

  def extract_token_profit_from_pool(%Pool{} = pool, "1_0"),
    do: pool.token_pair.token1

  def calculate_decimals_adjusted(%Pool{} = pool, "0_1"),
    do: pool.token_pair.decimals_adjuster_0_1 |> String.to_float()

  def calculate_decimals_adjusted(%Pool{} = pool, "1_0"),
    do: 1 / (pool.token_pair.decimals_adjuster_0_1 |> String.to_float())
end
