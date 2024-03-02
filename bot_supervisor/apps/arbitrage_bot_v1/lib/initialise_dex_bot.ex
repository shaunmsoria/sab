defmodule InitialiseDexBot do
  import Compute

  @dexs Libraries.dexs()
  @tokens Libraries.tokens()

  def run(state) do
    with  dex0 <- @dexs |> Map.get(state.dex0),
          dex1 <- @dexs |> Map.get(state.dex1),
          list_pair0 <- dex0 |> liquidity_pool_pair_data_extractor(),
          list_pair1 <- dex1 |> liquidity_pool_pair_data_extractor() do

      %ListPair{list_pair0: list_pair0, list_pair1: list_pair1}

    end
  end


  def liquidity_pool_pair_data_extractor(%Dex{} = dex) do
    with {:ok, %{"data" => data}} <- SubgraphApi.get_liquidity_pool_pairs(dex) do
      data
      |> process_list_pair()
    else
        error ->
            error
            |> IO.inspect(label: "error in liquidity_pool_pair_data_extractor is #{error}")
            {:error, error}
    end
  end

  def process_list_pair(%{"pairs" => pairs}) when is_list(pairs), do: pairs
  def process_list_pair(%{} = data), do: data



  def archive do
    System.get_env("ALCHEMY_API_KEY")
    |> IO.inspect(label: "sx1 ALCHEMY_API_KEY")

    @dexs.uniswap.factory
    |> IO.inspect(label: "sx1 FACTORY_ADDRESS")

    @dexs.uniswap.router
    |> IO.inspect(label: "sx1 V2_ROUTER_02_ADDRESS")

    {:ok, pair_address_uni} =
      Compute.get_pair_address(
        @dexs.uniswap.factory,
        @tokens.weth.address,
        @tokens.shib.address
      )

    {:ok, pair_address_sushi} =
      Compute.get_pair_address(
        @dexs.sushiswap.factory,
        @tokens.weth.address,
        @tokens.shib.address
      )

    pair_address_uni
    |> contract(:get_reserves)
    |> IO.inspect(label: "sx1 pair_address_uni |> contract(:get_reserves)")

    price_0 =
      pair_address_uni
      |> calculate_price()
      |> IO.inspect(label: "sx1 price_0")

    pair_address_sushi
    |> contract(:get_reserves)
    |> IO.inspect(label: "sx1 pair_address_sushi |> contract(:get_reserves)")

    price_1 =
      pair_address_sushi
      |> calculate_price()
      |> IO.inspect(label: "sx1 price_1")

    calculate_difference(price_0, price_1)
    |> IO.inspect(label: "sx1 calculate_difference")

    {:ok, _result} =
      Compute.get_all_pairs(@dexs.uniswap.factory, 0)
      |> IO.inspect(label: "sx1 Compute.get_all_pairs")

    {:ok, :done}
  end

end

## references:

# LiquidityPoolContract.EventFilters.swap(pair_address_uni, nil)
# |> Ethers.get_logs()
# |> IO.inspect(label: "sx1 EventFilters")

# pair_address_uni |> contract_logs(:swap)
# |> IO.inspect(label: "sx1 pair_address_uni |> contract(:swap)")




# {:ok, _pair_address_uni} =
#   Compute.get_pair_address(
#     @dexs.uniswap.factory,
#     @tokens.weth.address,
#     @tokens.shib.address
#   )
