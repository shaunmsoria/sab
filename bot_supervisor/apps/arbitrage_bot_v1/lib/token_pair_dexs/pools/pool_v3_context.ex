defmodule PoolV3Context do
  import Compute
  alias TokenPairContext, as: TPC
  alias PoolAddressContext, as: PAC
  alias PoolSearch, as: PS
  alias PoolContext, as: PC

  def initialise(), do: PoolV3Initialise.run()

  def get_or_create_pool_v3(
        "0x0000000000000000000000000000000000000000",
        _dex_v3,
        _token_pair,
        _pool_v3_fee
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
        pool_v3_fee
      ) do
    {:ok, updated_token_pair} = token_pair |> TPC.update_decimals_adjuster_0_1()

    get_or_create_pool_v3(pool_v3_address, dex_v3, updated_token_pair, pool_v3_fee)
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
        pool_v3_fee
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

    {:ok, %PoolAddress{id: token_pair_address_id} = token_pair_address} =
      PAC.maybe_add_token_pair_address(pool_v3_address)

    {:ok, updated_token_pair} =
      PC.maybe_add_token_pair_dex(token_pair_address, token0, token1, dex_v3, %{
        token_pair_address_id: token_pair_address_id,
        address: pool_v3_address,
        upcase_address: String.upcase(pool_v3_address),
        fee: pool_v3_fee,
        price: price,
        reserve0: reserve0,
        reserve1: reserve1,
        tick: tick_current |> Integer.to_string(),
        tick_spacing: tick_spacing |> Integer.to_string()
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
      do: {"0.0", "0.0", "0.0"}

  def calculate_price_reserve0_reserve1(
        liquidity,
        sqrtPriceX96,
        tick_current,
        tick_spacing,
        decimals_adjuster_0_1,
        decimals0,
        decimals1
      ) do
    tick_lower =
      Float.floor(tick_current / tick_spacing) * tick_spacing

    tick_upper = tick_lower + tick_spacing

    case sqrtPriceX96 do
      0 ->


        price_lower = (1.0001 ** tick_lower) |> IO.inspect(label: "mx1 price_lower result")
        price_upper = (1.0001 ** tick_upper) |> IO.inspect(label: "mx1 price_upper result")

        reserve0 =
          (liquidity * ( - 1 / :math.sqrt(price_upper)) / 10 ** decimals0)
          |> Float.to_string()
          |> IO.inspect(label: "mx1 reserve0 result")

        reserve1 =
          (liquidity * (:math.sqrt(price_lower) * - 1) / 10 ** decimals1)
          |> Float.to_string()
          |> IO.inspect(label: "mx1 reserve1 result")


        invert_price_t0_t1_sqrtPriceX96 = "0.0"
          |> IO.inspect(label: "mx1 invert_price_t0_t1_sqrtPriceX96")

        {"0.0", reserve0, reserve1}

      _ ->

        price_current =
          ((sqrtPriceX96 / 2 ** 96) ** 2)
          |> IO.inspect(label: "sx1 price_current")

        invert_price_current =
              (1 / (price_current * decimals_adjuster_0_1))
              |> IO.inspect(label: "mx1 invert_price_current result")

        price_lower = (1.0001 ** tick_lower) |> IO.inspect(label: "mx1 price_lower result")

        price_upper = (1.0001 ** tick_upper) |> IO.inspect(label: "mx1 price_upper result")

        reserve0 =
          (liquidity * (1 / :math.sqrt(price_current) - 1 / :math.sqrt(price_upper)) / 10 ** decimals0)
          |> Float.to_string()
          |> IO.inspect(label: "mx1 reserve0 result")

        reserve1 =
          (liquidity * (:math.sqrt(price_current) - :math.sqrt(price_lower)) / 10 ** decimals1)
          |> Float.to_string()
          |> IO.inspect(label: "mx1 reserve1 result")

        price_t0_t1_sqrtPriceX96 =
          (sqrtPriceX96 / 2 ** 96) ** 2 * decimals_adjuster_0_1

        invert_price_t0_t1_sqrtPriceX96 =
          (1 / price_t0_t1_sqrtPriceX96)
          |> Float.to_string()
          |> IO.inspect(label: "mx1 invert_price_t0_t1_sqrtPriceX96")

        {invert_price_t0_t1_sqrtPriceX96, reserve0, reserve1}

    end


  end
end
