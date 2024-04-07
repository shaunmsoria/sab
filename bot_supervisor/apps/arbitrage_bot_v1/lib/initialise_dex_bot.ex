defmodule InitialiseDexBot do
  import Compute

  @dexs Libraries.dexs()
  @tokens Libraries.tokens()

  def run(_state) do
    extract_list_pairs()
  end

##TODO how to store the token_pair price and access it?
##TODO how to update the token_pair price?
##TODO how to calculate token_pair profit from one dex to another? (including gas fees and LP fee and flash loan fees)

  def extract_list_pairs() do
    with state <- state_file() do
      new_state =
        @dexs
        |> Map.keys()
        |> Enum.map(fn dex_key ->
          %{
            "name" => dex_key,
            "list" =>
              @dexs
              |> Map.get(dex_key)
              |> dex_token_pair_state_constructor(state)
          }
        end)

      {:ok, file} = write_state_file(new_state)

      new_state
      |> IO.inspect(label: "sx1 new_state")
    end
  end

  def write_state_file(state) do
    state_jason =
      state |> Jason.encode!()

    with {:ok, file} <-
           File.open(
             "/home/shaun/volume/sab/bot_supervisor/apps/arbitrage_bot_v1/lib/libraries/state.json",
             [:write]
           ),
         :ok <-
           IO.binwrite(file, state_jason),
         :ok <- File.close(file) do
      {:ok, file}
    end
  end

  def state_file() do
    with {:ok, file} <-
           File.open(
             "/home/shaun/volume/sab/bot_supervisor/apps/arbitrage_bot_v1/lib/libraries/state.json",
             [:read]
           ),
         body <- IO.binread(file, :all),
         :ok <- File.close(file),
         true <- not String.equivalent?(body, "") do
      body |> Jason.decode!()
      # []
    else
      {:error, :enoent} ->
        []

      {:error, error} ->
        error |> IO.inspect(label: "state_file error: #{error}")
        []

      false ->
        []
    end
  end

  def dex_token_pair_state_constructor(dex, state) do
    with name <- dex |> Map.get("name"),
         factory_address <- @dexs |> Map.get(name) |> Map.get("factory"),
         %{"list" => list_token_pair} <-
           state |> ListDex.get_list_dex_from_name(name) do
      {list, count} =
        @tokens
        |> Enum.reduce({[], 1}, fn token, acc ->
          {token_pair_list, count} = acc

          {examined_tokens, reduced_tokens} =
            @tokens
            |> Enum.split(count)

          additional_token_pair_list =
            reduced_tokens
            |> Enum.reduce([], fn token_checked, acc2 ->
              acc2 ++ exist_token_pair(factory_address, list_token_pair, token, token_checked)
            end)

          {token_pair_list ++ additional_token_pair_list, count + 1}
        end)

      list
    end
  end

  def exist_token_pair(factory_address, list_token_pair, token, []), do: []

  def exist_token_pair(factory_address, list_token_pair, token, token_checked) do
    {name, token_value} = token
    {name_checked, token_value_checked} = token_checked

    with %{} <-
           ListDex.token_pair_from_list_dex(list_token_pair, %{
             "token0" => token_value,
             "token1" => token_value_checked
           }) do
      with {:ok, pair_address} <-
             Compute.get_pair_address(
               factory_address,
               token_value["address"],
               token_value_checked["address"]
             ) do
        if not String.equivalent?(pair_address, "0x0000000000000000000000000000000000000000") do
          [
            %{
              "token0" => token_value,
              "token1" => token_value_checked,
              "address" => pair_address
            } |> Map.merge(get_token_pair_price(pair_address))
          ]
        else
          []
        end
      end
    else
      token_pair ->
        [token_pair |> Map.merge(get_token_pair_price(token_pair["address"]))]
    end
  end

  def get_token_pair_price(token_pair) do
    %{"price" => Compute.calculate_price(token_pair)}
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
