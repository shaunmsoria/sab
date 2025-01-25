defmodule PoolV3Context do
  import Compute

  def initialise(), do: PoolV3Initialise.run()

  def get_of_create_pool_v3("0x0000000000000000000000000000000000000000", _decimals0, _decimals1), do: {:error, "no pool v3 for address 0x0000000000000000000000000000000000000000"}

  def get_of_create_pool_v3(pool_v3_address, decimals0, decimals1) do
    ## TODO functions to calculate the following:
    ## TODO aligned tick, lower tick, upper tick, reserve0 and reserve1 from ticks and liquidity
    ## TODO maybe add sqrtPriceX96 to TokerPairDex table?

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

    ## TODO in TokenPair
    decimals_adjuster =
      (10 ** (decimals0 - decimals1)) |> IO.inspect(label: "mx1 decimals_adjuster")

    tick_current |> IO.inspect(label: "mx1 tick_current")

    ## TODO in TokenPairDex
    tick_lower =
      (Float.floor(tick_current / tick_spacing) * tick_spacing)
      |> IO.inspect(label: "mx1 tick_lower result")

    tick_upper = (tick_lower + tick_spacing) |> IO.inspect(label: "mx1 tick_upper result")

    # ## TODO in TokenPairDex
    # tick_aligned =
    #   (Float.floor(tick_current / tick_spacing) * tick_spacing)
    #   |> IO.inspect(label: "mx1 tick_aligned result")

    # tick_lower = (tick_aligned - tick_spacing) |> IO.inspect(label: "mx1 tick_lower result")
    # tick_upper = (tick_aligned + tick_spacing) |> IO.inspect(label: "mx1 tick_upper result")

    price_current =
      ((sqrtPriceX96 / 2 ** 96) ** 2) |> IO.inspect(label: "mx1 price_current result")

    # price_current = (1.0001 ** tick_current) |> IO.inspect(label: "mx1 price_current result")

    ## TODO in TokenPairDex
    invert_price_current =
      (1 / (price_current * decimals_adjuster))
      |> IO.inspect(label: "mx1 invert_price_current result")

    price_lower = (1.0001 ** tick_lower) |> IO.inspect(label: "mx1 price_lower result")

    invert_price_lower =
      (1 / (price_current * decimals_adjuster))
      |> IO.inspect(label: "mx1 invert_price_lower result")

    price_upper = (1.0001 ** tick_upper) |> IO.inspect(label: "mx1 price_upper result")

    invert_price_upper =
      (1 / (price_upper * decimals_adjuster))
      |> IO.inspect(label: "mx1 invert_price_upper result")

    ## TODO in TokenPairDex
    reserve0 =
      (liquidity * (1 / :math.sqrt(price_current) - 1 / :math.sqrt(price_upper)) / 10 ** decimals0)
      |> IO.inspect(label: "mx1 reserve0 result")

    ## TODO in TokenPairDex
    reserve1 =
      (liquidity * (:math.sqrt(price_current) - :math.sqrt(price_lower)) / 10 ** decimals1)
      |> IO.inspect(label: "mx1 reserve1 result")



    price_t0_t1_sqrtPriceX96 =
      ((sqrtPriceX96 / 2 ** 96) ** 2 * decimals_adjuster)
      |> IO.inspect(label: "mx1 price_t0_t1_sqrtPriceX96")

    invert_price_t0_t1_sqrtPriceX96 =
      (1 / price_t0_t1_sqrtPriceX96)
      |> IO.inspect(label: "mx1 invert_price_t0_t1_sqrtPriceX96")

    IO.puts("mx1 #####################")

    # token_pair =
    #   TokenPairSearch.with_id(3)
    #   |> Repo.one()
    #   |> Repo.preload([:dexs, :token0, :token1])
    #   |> IO.inspect(label: "token_pair")
  end
end

# {:ok, updated_token_pair} = TPDC.maybe_add_token_pair_dex(token0, token1, dex_v3)

# token_pair_dex_v3 =
#   TPDS.with_token_pair_id(token_pair_id)
#   |> TPDS.with_dex_id(dex_v3_id)
#   |> Repo.one()

# {:ok, updated_token_pair_dex_v3} =
#   TPDC.update(
#     token_pair_dex_v3,
#     %{
#       address: pool_v3_address,
#       upcase_address: String.upcase(pool_v3_address),
#       fee: pool_v3_fee
#     }
#   )
#   |> IO.inspect(label: "sx1 updated_token_pair_dex_v3")
