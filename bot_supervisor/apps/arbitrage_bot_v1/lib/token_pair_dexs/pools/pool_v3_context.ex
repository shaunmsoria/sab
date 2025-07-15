defmodule PoolV3Context do
  import Compute
  alias TokenPairContext, as: TPC
  alias PoolAddressContext, as: PAC
  alias PoolSearch, as: PS
  alias PoolContext, as: PC
  alias PoolV3CheckProfit, as: PV3CP
  alias DexSearch, as: DS
  alias DexContext, as: DC
  alias LogWritter, as: LW

  def initialise(), do: PoolV3Initialise.run()

  def get_or_create_pool_v3(
        pool_v3_address,
        dex_v3,
        token_pair,
        pool_v3_fee
      ) do
    get_or_create_pool_v3(pool_v3_address, dex_v3, token_pair, pool_v3_fee, nil)
  end

  def get_or_create_pool_v3(
        "0x0000000000000000000000000000000000000000",
        _dex_v3,
        _token_pair,
        _pool_v3_fee,
        _n_pair
      ),
      do: {:error, "no pool v3 for address 0x0000000000000000000000000000000000000000"}

  def get_or_create_pool_v3(
        pool_v3_address,
        %Dex{} = dex_v3,
        %TokenPair{
          token0: %Token{} = token0,
          token1: %Token{} = token1,
          decimals_adjuster_0_1: nil
        } = token_pair,
        pool_v3_fee,
        n_pair
      ) do
    {:ok, updated_token_pair} = token_pair |> TPC.update_decimals_adjuster_0_1()

    get_or_create_pool_v3(pool_v3_address, dex_v3, updated_token_pair, pool_v3_fee, n_pair)
  end

  def get_or_create_pool_v3(
        pool_v3_address,
        %Dex{id: dex_v3_id} = dex_v3,
        %TokenPair{
          id: token_pair_id,
          token0: %Token{decimals: decimals0} = token0,
          token1: %Token{decimals: decimals1} = token1,
          decimals_adjuster_0_1: decimals_adjuster_0_1_string
        } = token_pair,
        pool_v3_fee,
        n_pair
      ) do
    pool_v3 =
      PS.with_dex_id(dex_v3_id)
      |> PS.with_token_pair_id(token_pair_id)
      |> PS.with_fee(pool_v3_fee)
      |> Repo.one()

    case pool_v3 do
      nil ->
        create_pool_v3(
          pool_v3_address,
          dex_v3,
          token0,
          token1,
          decimals0,
          decimals1,
          decimals_adjuster_0_1_string,
          pool_v3_fee,
          n_pair
        )

      %Pool{} = pool_v3 ->
        {:ok, pool_v3}
    end
  end

  def create_pool_v3(
        pool_v3_address,
        %Dex{id: dex_v3_id} = dex_v3,
        %Token{id: token0_id} = token0,
        %Token{id: token1_id} = token1,
        decimals0,
        decimals1,
        decimals_adjuster_0_1_string,
        pool_v3_fee,
        n_pair
      ) do
    {:ok, tick_spacing} =
      pool(pool_v3_address, "uniswapV3", :tick_spacing)
      |> IO.inspect(label: "mx1 pool tick_spacing result")

    {:ok, liquidity} =
      pool(pool_v3_address, "uniswapV3", :liquidity)
      |> IO.inspect(label: "mx1 pool liquidity result")

    {:ok,
     [
       sqrtPriceX96,
       tick_current,
       _observationIndex,
       _observationCardinality,
       _observationCardinalityNext,
       _feeProtocol,
       _unlocked
     ]} =
      pool(pool_v3_address, "uniswapV3", :slot0)
      |> IO.inspect(label: "mx1 pool slot0 result")

    decimals_adjuster_0_1 = decimals_adjuster_0_1_string |> String.to_float()

    {price, reserve0, reserve1} =
      calculate_price_reserve0_reserve1(
        liquidity,
        sqrtPriceX96,
        tick_current,
        tick_spacing,
        decimals_adjuster_0_1,
        decimals0,
        decimals1
      )

    IO.puts("mx1 #####################")

    {:ok, %PoolAddress{id: pool_address_id} = pool_address} =
      PAC.maybe_add_pool_address(pool_v3_address)

    {:ok, updated_pool} =
      PC.maybe_add_pool(pool_address, token0, token1, dex_v3, %{
        pool_address_id: pool_address_id,
        address: pool_v3_address,
        upcase_address: String.upcase(pool_v3_address),
        fee: pool_v3_fee,
        price: price,
        reserve0: reserve0,
        reserve1: reserve1,
        tick: tick_current |> Integer.to_string(),
        tick_spacing: tick_spacing |> Integer.to_string(),
        n_pair: n_pair,
        liquidity: liquidity |> Integer.to_string()
      })
  end

  def calculate_price_reserve0_reserve1(
        0,
        _sqrtPriceX96,
        _tick_current,
        _tick_spacing,
        _decimals_adjuster_0_1,
        _decimals0,
        _decimals1
      ),
      do: {"0.0", "0", "0"}

  def calculate_price_reserve0_reserve1(
        liquidity,
        sqrtPriceX96,
        tick_current,
        tick_spacing_raw,
        decimals_adjuster_0_1_raw,
        decimals0,
        decimals1
      ) do
    tick_spacing = sanitise_from_string_to_float(tick_spacing_raw)

    decimals_adjuster_0_1 = sanitise_from_string_to_float(decimals_adjuster_0_1_raw)

    tick_current |> IO.inspect(label: "mx1 tick_current")
    tick_spacing |> IO.inspect(label: "mx1 tick_spacing")

    tick_lower =
      Float.floor(tick_current / tick_spacing) * tick_spacing

    tick_upper = tick_lower + tick_spacing

    case sqrtPriceX96 do
      0 ->
        price_lower =
          (1.0001 ** tick_lower)
          |> IO.inspect(label: "mx1 price_lower result")

        price_upper = (1.0001 ** tick_upper) |> IO.inspect(label: "mx1 price_upper result")

        reserve0 =
          (liquidity * (-1 / :math.sqrt(price_upper)) / 10 ** decimals0)
          |> trunc()
          |> Integer.to_string()
          |> IO.inspect(label: "mx1 reserve0 result")

        reserve1 =
          (liquidity * (:math.sqrt(price_lower) * -1) / 10 ** decimals1)
          |> trunc()
          |> Integer.to_string()
          |> IO.inspect(label: "mx1 reserve1 result")

        invert_price_t0_t1_sqrtPriceX96 =
          "0.0"
          |> IO.inspect(label: "mx1 invert_price_t0_t1_sqrtPriceX96")

        {"0.0", reserve0, reserve1}

      _ ->
        price_current =
          ((sqrtPriceX96 / 2 ** 96) ** 2)
          |> IO.inspect(label: "sx1 price_current")

        invert_price_current =
          (1 / (price_current * decimals_adjuster_0_1))
          |> IO.inspect(label: "sx1 invert_price_current result")

        price_lower = (1.0001 ** tick_lower) |> IO.inspect(label: "mx1 price_lower result")

        price_upper = (1.0001 ** tick_upper) |> IO.inspect(label: "mx1 price_upper result")

        reserve0 =
          (liquidity * (1 / :math.sqrt(price_current) - 1 / :math.sqrt(price_upper)))
          |> trunc()
          |> Integer.to_string()
          |> IO.inspect(label: "sx1 reserve0 result")

        reserve1 =
          (liquidity * (:math.sqrt(price_current) - :math.sqrt(price_lower)))
          |> trunc()
          |> Integer.to_string()
          |> IO.inspect(label: "sx1 reserve1 result")

        price_t1_t0_sqrtPriceX96 =
          ((sqrtPriceX96 / 2 ** 96) ** 2 * decimals_adjuster_0_1)
          |> IO.inspect(label: "sx1 price_t1_t0_sqrtPriceX96")

        price_t0_t1_sqrtPriceX96 =
          (1 / price_t1_t0_sqrtPriceX96)
          |> Float.to_string()
          |> IO.inspect(label: "sx1 price_t0_t1_sqrtPriceX96")

        {price_t0_t1_sqrtPriceX96, reserve0, reserve1}
    end
  end

  def check_profit(%Pool{} = pool, {amount0_delta, amount1_delta, liquidity, sqrtPriceX96, tick}),
    do: PV3CP.run(pool, {amount0_delta, amount1_delta, liquidity, sqrtPriceX96, tick})

  def update_pool_change(%Pool{address: pool_v3_address} = pool) do
    {:ok, liquidity} =
      pool(pool_v3_address, "uniswapV3", :liquidity)
      |> IO.inspect(label: "mx1 pool liquidity result")

    {:ok,
     [
       sqrtPriceX96,
       tick_current,
       _observationIndex,
       _observationCardinality,
       _observationCardinalityNext,
       _feeProtocol,
       _unlocked
     ]} =
      pool(pool_v3_address, "uniswapV3", :slot0)
      |> IO.inspect(label: "mx1 pool slot0 result")
  end

  def sanitise_from_string_to_float(nil), do: 0.0
  def sanitise_from_string_to_float(""), do: 0.0

  def sanitise_from_string_to_float(string) when is_binary(string) do
    case string |> String.split(".") |> length > 1 do
      true -> string |> String.to_float()
      false -> string |> String.to_integer()
    end
  end

  def sanitise_from_string_to_float(value) when is_integer(value),
    do: value |> Integer.to_string() |> Float.parse() |> elem(0)

  def sanitise_from_string_to_float(float) when is_float(float), do: float

  def maybe_add_all_pool_v3(token_pair, pool_address) do
    all_dexs_v3 = DS.with_abi("uniswapV3") |> Repo.all()

    list_pools =
      all_dexs_v3
      |> Enum.map(fn dex_v3 ->
        maybe_add_pools_from_fees(token_pair, dex_v3)
      end)
      |> List.flatten()

    {:ok, list_pools}
  end

  @pool_v3_fees ["100", "500", "3000", "10000"]
  def maybe_add_pools_from_fees(token_pair, dex_v3) do
    tp_preloaded = token_pair |> Repo.preload([:token0, :token1])

    @pool_v3_fees
    |> Enum.map(fn pool_v3_fee ->
      get_pool_address(
        dex_v3.factory,
        tp_preloaded.token0.address,
        tp_preloaded.token1.address,
        pool_v3_fee |> String.to_integer()
      )
      |> case do
        {:ok, pool_v3_address} ->
          pool_v3_address
          |> IO.inspect(label: "sx1 pool_address")

          with {:ok, pool_v3} <-
                 get_or_create_pool_v3(
                   pool_v3_address,
                   dex_v3,
                   tp_preloaded,
                   pool_v3_fee
                 ) do
            pool_v3
          else
            msg ->
              LW.ipt(inspect(msg))
              []
          end

        nil ->
          LW.ipt(
            "no pool v3 for token_pair_id: #{token_pair.id} with dex_id: #{dex_v3.id} and fee: #{pool_v3_fee}"
          )

          []
      end
    end)
    |> IO.inspect(label: "sx1 maybe_add_pools_from_fees")
    |> List.flatten()
    |> IO.inspect(label: "sx1 maybe_add_pools_from_fees after List.flatten")
  end
end
