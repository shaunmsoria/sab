defmodule InitialiseDexBot do
  import Compute

  @dexs Libraries.dexs()
  @tokens Libraries.tokens()

  def run(state) do
    extract_list_pairs(state)
  end

  def extract_list_pairs(state) do
    @dexs
    |> Map.keys()
    |> Enum.map(fn dex_key ->
      %{
        name: dex_key,
        list:
          @dexs
          |> Map.get(dex_key)
          |> dex_token_pair_state_constructor(state)
      }
    end)
  end

  def dex_token_pair_state_constructor(%Dex{} = dex, [] = state) do
    with name <- dex |> Map.get(:name) |> String.to_atom(),
         factory_address <- @dexs |> Map.get(name) |> Map.get(:factory) do
      list =
        @tokens
        |> Enum.reduce({[], 1}, fn token, acc ->
          {token_pair_list, count} = acc

          {examined_tokens, reduced_tokens} =
            @tokens
            |> Enum.split(count)

          additional_token_pair_list =
            reduced_tokens
            |> Enum.reduce([], fn token_checked, acc2 ->
              acc2 ++ exist_token_pair(factory_address, token, token_checked)
            end)

          {token_pair_list ++ additional_token_pair_list, count + 1}
        end)

      %{
        name: name,
        list: list
      }
    end
  end

  def exist_token_pair(factory_address, token, []), do: []

  def exist_token_pair(factory_address, token, token_checked) do
    with {:ok, pair_address} <-
           Compute.get_pair_address(
             factory_address,
             token |> Keyword.get_values() |> Map.get(:address), ##TODO fix access to this address
             token_checked.address
           ) do
      if not String.equivalent?(pair_address, "0x0000000000000000000000000000000000000000") do
        [
          %TokenPair{
            token0: token,
            token1: token_checked,
            address: pair_address
          }
        ]
      else
        []
      end
    end
  end

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
