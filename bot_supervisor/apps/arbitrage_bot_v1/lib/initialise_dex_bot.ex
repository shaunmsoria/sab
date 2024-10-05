defmodule InitialiseDexBot do
  import Compute
  alias LogWritter, as: LW
  # import LogWritter

  @dexs Libraries.dexs()
  @tokens Libraries.tokens()
  @balancer Libraries.balancer()

  def run(_state) do
    extract_list_pairs()
  end

  def extract_list_pairs() do
    with state <- state_file(),
         :ok <- ConCache.put(:dex, "list_dex", @dexs |> Map.keys()) do
      new_state =
        @dexs
        |> Map.keys()
        |> Enum.map(fn dex_key ->
          %{
            "name" => dex_key,
            "content" =>
              @dexs
              |> Map.get(dex_key)
              |> dex_token_pair_state_constructor(state)
          }
        end)

      {:ok, _file} = write_state_file(new_state)

      ConCache.get(:dex, "list_dex")
      |> LW.ipt("sx1 test in initialise")

      new_state
    end
  end

  def write_state_file(state) do
    state_jason =
      state |> Jason.encode!()

    with {:ok, file} <-
           File.open(
             "/home/server/Programs/sab/bot_supervisor/apps/arbitrage_bot_v1/lib/libraries/json/state.json",
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
             "/home/server/Programs/sab/bot_supervisor/apps/arbitrage_bot_v1/lib/libraries/json/state.json",
             [:read]
           ),
         body <- IO.binread(file, :eof),
         :ok <- File.close(file),
         true <- not String.equivalent?(body, "") do
      body |> Jason.decode!()
    else
      {:error, :enoent} ->
        %{}

      {:error, error} ->
        error |> LogWritter.ipt("state_file error: #{error}")
        %{}

      false ->
        %{}
    end
  end

  def dex_token_pair_state_constructor(dex, state) do
    with name <- dex |> Map.get("name"),
         factory_address <-
           @dexs
           |> Map.get(name)
           |> Map.get("factory"),
         %{"content" => map_token_pair} <-
           state
           |> ListDex.get_list_dex_from_name(name),
         :ok <- ConCache.put(:dex, name, map_token_pair) do
      {processed_token_pair, _count} =
        @tokens
        |> Enum.reduce({%{}, 1}, fn token, acc ->
          {token_pair_list, count} = acc

          {_examined_tokens, reduced_tokens} =
            @tokens
            |> Enum.split(count)

          additional_token_pair_list =
            reduced_tokens
            |> Enum.reduce(%{}, fn token_checked, acc2 ->
              Map.merge(
                acc2,
                exist_token_pair(factory_address, map_token_pair, token, token_checked)
              )
            end)

          {Map.merge(token_pair_list, additional_token_pair_list), count + 1}
        end)

      processed_token_pair
    end
  end

  def exist_token_pair(_factory_address, _map_token_pair, _token, %{}), do: %{}

  def exist_token_pair(factory_address, nil, token, token_checked) do
    {_name, token_value} = token
    {_name_checked, token_value_checked} = token_checked

    with {:ok, pair_address} <-
           Compute.get_pair_address(
             factory_address,
             token_value["address"],
             token_value_checked["address"]
           ) do
      if not String.equivalent?(pair_address, "0x0000000000000000000000000000000000000000") do
        %{
          pair_address =>
            %{
              "token0" => token_value,
              "token1" => token_value_checked,
              "address" => pair_address
            }
            |> Map.merge(get_token_pair_price(pair_address))
        }
      else
        %{}
      end
    end
  end

  def exist_token_pair(factory_address, map_token_pair, token, token_checked) do
    {_name, token_value} = token
    {_name_checked, token_value_checked} = token_checked

    with %{} <-
           ListDex.token_pair_from_list_dex(map_token_pair, %{
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
          %{
            pair_address =>
              %{
                "token0" => token_value,
                "token1" => token_value_checked,
                "address" => pair_address
              }
              |> Map.merge(get_token_pair_price(pair_address))
          }
        else
          %{}
        end
      end
    else
      {_address, token_pair} ->
        %{
          token_pair["address"] =>
            token_pair |> Map.merge(get_token_pair_price(token_pair["address"]))
        }
    end
  end

  def get_token_pair_price(token_pair) do
    %{"price" => Compute.calculate_price(token_pair)}
  end

  def archive do
    System.get_env("ALCHEMY_API_KEY")
    |> LogWritter.ipt("sx1 ALCHEMY_API_KEY")

    @dexs.uniswap.factory
    |> LogWritter.ipt("sx1 FACTORY_ADDRESS")

    @dexs.uniswap.router
    |> LogWritter.ipt("sx1 V2_ROUTER_02_ADDRESS")

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
    |> LogWritter.ipt("sx1 pair_address_uni |> contract(:get_reserves)")

    price_0 =
      pair_address_uni
      |> calculate_price()
      |> LogWritter.ipt("sx1 price_0")

    pair_address_sushi
    |> contract(:get_reserves)
    |> LogWritter.ipt("sx1 pair_address_sushi |> contract(:get_reserves)")

    price_1 =
      pair_address_sushi
      |> calculate_price()
      |> LogWritter.ipt("sx1 price_1")

    calculate_difference(price_0, price_1)
    |> LogWritter.ipt("sx1 calculate_difference")

    {:ok, _result} =
      Compute.get_all_pairs(@dexs.uniswap.factory, 0)
      |> LogWritter.ipt("sx1 Compute.get_all_pairs")

    {:ok, :done}
  end
end

## references:

# LiquidityPoolContract.EventFilters.swap(pair_address_uni, nil)
# |> Ethers.get_logs()
# |> LogWritter.ipt("sx1 EventFilters")

# pair_address_uni |> contract_logs(:swap)
# |> LogWritter.ipt("sx1 pair_address_uni |> contract(:swap)")

# {:ok, _pair_address_uni} =
#   Compute.get_pair_address(
#     @dexs.uniswap.factory,
#     @tokens.weth.address,
#     @tokens.shib.address
#   )
