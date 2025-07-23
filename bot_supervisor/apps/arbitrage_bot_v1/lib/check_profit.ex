defmodule CheckProfit do
  alias ElixirSense.Log
  import Compute

  ## ? v2 flow
  def run(
        %Pool{dex: %Dex{abi: "uniswapV2"}} = pool_event,
        params
      ),
      do:
        pool_event
        |> PoolContext.update_pool_price(:pool_event)
        |> check_event_pool_ratio(params)

  def check_event_pool_ratio({:error, message}, _params),
    do: {:error, message} |> IO.inspect(label: "sx1 check_event_pool_ratio")

  def check_event_pool_ratio(
        {:ok, %Pool{} = pool_event},
        {amount0_in, amount0_out, amount1_in, amount1_out} = params
      ) do
    case {amount1_out >= calculate_pool_ratio(pool_event.reserve1),
          amount0_out >= calculate_pool_ratio(pool_event.reserve0)} do
      {true, false} ->
        get_profitable_trade_from_pool(pool_event, %{
          burrow_token: pool_event.token_pair.token0,
          swap_token: pool_event.token_pair.token1,
          swap_amount: amount1_out,
          swap_direction: "0_1"
        })

      {false, true} ->
        get_profitable_trade_from_pool(pool_event, %{
          burrow_token: pool_event.token_pair.token1,
          swap_token: pool_event.token_pair.token0,
          swap_amount: amount0_out,
          swap_direction: "1_0"
        })

      {false, false} ->
        {:error,
         "Pool_id: #{pool_event.id} Event amount0_out: #{amount0_out} and amount1_out: #{amount1_out} below event_threshold"}

      {true, true} ->
        {:error,
         "Pool_id: #{pool_event.id} Both amount0_out: #{amount0_out} and amount1_out: #{amount1_out} above 0"}
    end
  end

  @threshold_percentage 0.00000000001
  def calculate_pool_ratio(nil), do: 0
  def calculate_pool_ratio(0), do: 0

  def calculate_pool_ratio(amount_pool),
    do: (amount_pool |> String.to_integer()) * @threshold_percentage

  ## ? v3 flow
  def run(
        %Pool{dex: %Dex{abi: "uniswapV3"}} = pool_event,
        {amount0_delta, amount1_delta, liquidity, sqrtPriceX96, tick} = params
      ) do
    {price_0_1, reserve0, reserve1} =
      PoolV3Context.calculate_price_reserve0_reserve1(
        liquidity,
        sqrtPriceX96,
        tick,
        pool_event.tick_spacing,
        pool_event.token_pair.decimals_adjuster_0_1,
        pool_event.token_pair.token0.decimals,
        pool_event.token_pair.token1.decimals
      )

    {:ok, updated_pool_event} =
      PoolContext.update(
        pool_event,
        %{
          price: price_0_1,
          reserve0: reserve0,
          reserve1: reserve1,
          tick: tick |> Integer.to_string(),
          liquidity: liquidity |> Integer.to_string()
        }
      )

    define_direction(updated_pool_event, amount0_delta, amount1_delta)
  end

  def define_direction(%Pool{} = pool_event, amount0_delta, amount1_delta) when amount0_delta > 0,
    do:
      get_profitable_trade_from_pool(pool_event, %{
        burrow_token: pool_event.token_pair.token0,
        swap_token: pool_event.token_pair.token1,
        swap_amount: amount1_delta * -1,
        swap_direction: "0_1"
      })

  def define_direction(%Pool{} = pool_event, amount0_delta, amount1_delta)
      when amount0_delta <= 0,
      do:
        get_profitable_trade_from_pool(pool_event, %{
          burrow_token: pool_event.token_pair.token1,
          swap_token: pool_event.token_pair.token0,
          swap_amount: amount0_delta * -1,
          swap_direction: "1_0"
        })

  ## ? check profit flow
  def get_profitable_trade_from_pool(%Pool{price: "0.0"} = pool_event, _params),
    do: {:error, "pool event with id: #{pool_event.id} price is 0.0"}

  def get_profitable_trade_from_pool(%Pool{price: nil} = pool_event, _params),
    do: {:error, "pool event with id: #{pool_event.id} price is nil"}

  def get_profitable_trade_from_pool(%Pool{} = pool_event, params) do
    swap_price_event = calculate_price_with_direction(pool_event.price, params.swap_direction)

    get_profitable_trades(pool_event, params.swap_amount, swap_price_event, params.swap_direction)
  end

  # todo tdx1 remove the the dex_abi filter
  def get_profitable_trades(%Pool{} = pool_event, swap_amount, swap_price_event, swap_direction) do
    PoolSearch.with_token_pair_id(pool_event.token_pair.id)
    |> LogWritter.ipt("sx1 PoolSearch.with_token_pair_id")
    |> PoolSearch.with_dex_abi("uniswapV3")
    |> Repo.all()
    |> estimate_profitable_pool(pool_event, swap_amount, swap_price_event, swap_direction)
    |> Enum.sort_by(
      fn {_pool_event, _pool_search, profit_amount, _token_return_symbol, _return_amount,
          _burrow_amount, _token_return_amount_for_gas_fee, _swap_price_event, _swap_direction,
          _swap_amount} ->
        profit_amount
      end,
      :desc
    )
  end

  def estimate_profitable_pool(
        %Pool{} = pool_search,
        pool_event,
        swap_amount,
        swap_price_event,
        swap_direction
      ),
      do:
        estimate_profitable_pool(
          [pool_search],
          pool_event,
          swap_amount,
          swap_price_event,
          swap_direction
        )

  def estimate_profitable_pool([], _, _, _, _), do: []

  def estimate_profitable_pool(
        list_pool_search,
        pool_event_unpreloaded,
        swap_amount,
        swap_price_event,
        swap_direction
      )
      when is_list(list_pool_search) do
    pool_event = pool_event_unpreloaded |> Repo.preload(token_pair: [:token0, :token1])
    decimals_adjusted = calculate_decimals_adjusted(pool_event, swap_direction)

    list_pool_search
    |> Enum.filter(fn pool_search ->
      swap_price_searched = calculate_price_with_direction(pool_search.price, swap_direction)

      ##
      swap_direction |> LogWritter.ipt("sx1 swap_direction")
      swap_price_event |> LogWritter.ipt("sx1 swap_price_event")
      pool_event.id |> LogWritter.ipt("sx1 pool_event.id")
      swap_price_searched |> LogWritter.ipt("sx1 swap_price_searched")
      pool_search.id |> LogWritter.ipt("sx1 pool_search.id")

      (not is_nil(swap_price_searched) and swap_price_event > swap_price_searched)
      |> LogWritter.ipt("sx1 swap_price_event > swap_price_searched")

      ##

      not is_nil(swap_price_searched) and swap_price_event > swap_price_searched
    end)
    |> Enum.map(fn pool_search_unpreloaded ->
      pool_search = pool_search_unpreloaded |> Repo.preload(token_pair: [:token0, :token1])

      {swap_amount_adjusted, burrow_amount} =
        calculate_swap_and_burrow_amount_adjusted(
          pool_search,
          swap_amount,
          swap_direction,
          decimals_adjusted
        )

      swap_price_event = calculate_price_with_direction(pool_event.price, swap_direction)

      return_amount =
        calculate_return_amount(
          swap_amount_adjusted,
          swap_price_event,
          pool_event.fee,
          decimals_adjusted
        )

      {token_return_amount_for_gas_fee, token_return} =
        calculate_gas_price_for_trade_v3(
          extract_token_profit_from_pool(pool_event, swap_direction)
        )

      ##
      swap_amount_adjusted |> LogWritter.ipt("sx1 swap_amount_adjusted")
      return_amount |> LogWritter.ipt("sx1 return_amount")
      token_return |> LogWritter.ipt("sx1 token_return")
      burrow_amount |> LogWritter.ipt("sx1 burrow_amount")
      token_return_amount_for_gas_fee |> LogWritter.ipt("sx1 token_return_amount_for_gas_fee")
      ##

      profit_amount =
        (return_amount - burrow_amount - token_return_amount_for_gas_fee)
        |> LogWritter.ipt("sx1 profit_amount")

      {pool_event, pool_search, profit_amount, token_return, return_amount, burrow_amount,
       token_return_amount_for_gas_fee, swap_price_event, swap_direction, swap_amount}
    end)
    |> Enum.filter(fn {_, _, profit_amount, _, _, _, _, _, _, _} ->
      profit_amount > 0
    end)
  end

  def calculate_decimals_adjusted(%Pool{} = pool, "0_1"),
    do: pool.token_pair.decimals_adjuster_0_1 |> String.to_float()

  def calculate_decimals_adjusted(%Pool{} = pool, "1_0"),
    do: 1 / (pool.token_pair.decimals_adjuster_0_1 |> String.to_float())

  def calculate_price_with_direction("0.0", _), do: nil
  def calculate_price_with_direction(nil, _), do: nil

  def calculate_price_with_direction(pool_price, direction) when direction in ["0_1", :O_I],
    do: pool_price |> String.to_float()

  def calculate_price_with_direction(pool_price, direction) when direction in ["1_0", :I_O],
    do: 1 / (pool_price |> String.to_float())

  def calculate_swap_and_burrow_amount_adjusted(
        %Pool{} = pool,
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

    pool_reserve = sanitise_pool_reserve(pool.reserve0)

    LogWritter.ipt("sx1 calculate_swap_and_burrow_amount_adjusted 0_1")
    swap_amount_estimated |> LogWritter.ipt("sx1 swap_amount_estimated")
    burrow_amount_estimated |> LogWritter.ipt("sx1 burrow_amount_estimated")
    pool.reserve1 |> LogWritter.ipt("sx1 pool.reserve1")
    pool_reserve |> LogWritter.ipt("sx1 pool_reserve")
    pool.id |> LogWritter.ipt("sx1 pool.id")

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

    pool_reserve = sanitise_pool_reserve(pool.reserve1)

    LogWritter.ipt("sx1 calculate_swap_and_burrow_amount_adjusted 1_0")
    burrow_amount_estimated |> LogWritter.ipt("sx1 burrow_amount_estimated")
    pool_reserve |> LogWritter.ipt("sx1 pool_reserve")
    pool.reserve0 |> LogWritter.ipt("sx1 pool.reserve0")
    pool.id |> LogWritter.ipt("sx1 pool.id")

    {swap_amount, burrow_amount} =
      case burrow_amount_estimated <= pool_reserve do
        true ->
          {swap_amount_estimated, burrow_amount_estimated}

        false ->
          {pool_reserve / burrow_amount_estimated * swap_amount_estimated, pool_reserve}
      end
  end

  def sanitise_pool_reserve(nil), do: 0
  def sanitise_pool_reserve(""), do: 0
  def sanitise_pool_reserve(reserve), do: reserve |> String.to_integer()

  def calculate_burrow_amount(swap_amount, swap_price, pool_fee, decimals_adjusted) do
    pool_fee_ratio = 1 + (pool_fee |> String.to_integer()) / 10000
    swap_amount * swap_price * pool_fee_ratio * decimals_adjusted
  end

  def calculate_return_amount(swap_amount, swap_price, pool_fee, decimals_adjusted) do
    pool_fee_ratio = 1 - (pool_fee |> String.to_integer()) / 10000
    swap_amount * swap_price * pool_fee_ratio * decimals_adjusted
  end

  def extract_token_profit_from_pool(%Pool{} = pool, "0_1"),
    do: pool.token_pair.token0

  def extract_token_profit_from_pool(%Pool{} = pool, "1_0"),
    do: pool.token_pair.token1
end
