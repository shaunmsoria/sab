defmodule CheckProfit do
  import Compute
  alias ListDex, as: LD
  alias DexSearch, as: DS
  alias TokenContext, as: TC
  alias StateConstructor, as: SC
  alias TokenPairDexSearch, as: TPDS
  alias TokenPairDexContext, as: TPDC

  @dexs Libraries.dexs()
  @balancer Libraries.balancer()

  def run(_state, event_data) when is_map(event_data) do
    with true <-
           not String.equivalent?(event_data.event.address, ""),
         token_pair_dex_address <- event_data.event.address |> IO.inspect(label: "sx1 address"),
         {:ok,
          %TokenPairDex{
            token_pair: %TokenPair{status: "active"} = token,
            dex: %Dex{name: dex_name} = dex
          } = token_pair_dex} <-
           extract_token_pair_dex_details(token_pair_dex_address),
         {:ok, token_pair_dex_udpated} <- TPDC.update_token_pair_dex_price(token_pair_dex),
         {:ok, list_of_profitable_trades} <-
           get_profitable_trade(token_pair_dex_udpated) do
      ExecuteTrade.run(list_of_profitable_trades)
    else
      error ->
        error |> IO.inspect(label: "sx1 error:")
    end
  end

  def extract_token_pair_dex_details(token_pair_dex_address) do
    with token_pair_dex_searched <- TPDS.with_address(token_pair_dex_address) |> Repo.one(),
         true <- not is_nil(token_pair_dex_searched),
         token_pair_dex_preloaded <-
           token_pair_dex_searched
           |> Repo.preload([[token_pair: [:dexs, :token0, :token1]], :dex]) do
      {:ok, token_pair_dex_preloaded}
    end
  end

  # def found_dex_token_pair?(address) do
  #   with {:ok, token_pair} <- LD.get_dex_token_pair_from_address(address) do
  #     {:ok, token_pair} |> LogWritter.ipt("sx1 found_dex_token_pair? token_pair found")
  #   else
  #     _ ->
  #       with {:ok, map_new_tokens} <- get_token_metadata_from_token_pair(address),
  #       {:ok, new_tokens} <- SC.fetch_new_tokens(),
  #       updated_new_tokens <-
  #         map_new_tokens
  #         |> Enum.reduce(new_tokens, fn {map_new_token_key, map_new_token_value}, acc ->
  #           Map.update(acc,  map_new_token_key, map_new_token_value, fn existing_value -> existing_value end)
  #         end),
  #         :ok <- ConCache.put(:tokens, "new_tokens", updated_new_tokens) do

  #         {:error, "Tokens from #{address} will be added to the state"}
  #         # |> LogWritter.ipt("sx1 found_dex_token_pair? token_pair added:")
  #       else
  #         error ->
  #           error
  #           |> IO.inspect(
  #             label: "sx1 found_dex_token_pair? \n Token already waiting for processing"
  #           )
  #       end
  #   end
  # end

  # def get_token_metadata_from_token_pair(token_pair_address) when is_binary(token_pair_address) do
  #   with {:ok, token0_address} <- token_pair_address |> contract(:token0),
  #        {:ok, token1_address} <- token_pair_address |> contract(:token1) do
  #     tokens_to_be_added =
  #       [token0_address, token1_address]
  #       |> Enum.reduce(%{}, fn token_address, acc ->
  #         case TC.isTokenInMemory?(token_address) do
  #           true ->
  #             acc

  #           false ->
  #             with {:ok, token_symbol} <- token_address |> contract(:symbol),
  #                  {:ok, token_name} <- token_address |> contract(:name),
  #                  {:ok, token_decimals} <- token_address |> contract(:decimals) do
  #               acc
  #               |> Map.merge(%{
  #                 String.upcase(token_address) => %{
  #                   "name" => token_name,
  #                   "symbol" => token_symbol,
  #                   "address" => token_address,
  #                   "decimals" => token_decimals
  #                 }
  #               })
  #             else
  #               _ -> %{}
  #             end
  #         end
  #       end)

  #     {:ok, tokens_to_be_added}
  #   end
  # end

  def update_token_pair_price(token_pair, dex_name, price) do
    with :ok <-
           ConCache.update(:dex, dex_name, fn dex_content ->
             {:ok, %{dex_content | token_pair["address"] => %{token_pair | "price" => price}}}
           end) do
      {:ok, ConCache.get(:dex, dex_name) |> Map.get(token_pair["address"])}
    end
  end

  def maybe_profitable_trade(
        %TokenPairDex{price: token_pair_dex_price} = token_pair_dex,
        %TokenPairDex{price: token_pair_dex_searched_price} = token_pair_dex_searched
      ) do
        with price_difference <- Compute.calculate_difference(
          token_pair_dex_price,
          token_pair_dex_searched_price
        ) do
          case price_difference do
            0 -> []
            price_difference ->

          end

        end
  end

  def get_profitable_trade(
        %TokenPairDex{
          dex:
            %Dex{
              name: dex_name
            } = dex,
          token_pair:
            %TokenPair{
              dexs: dexs,
              token0: token0,
              token1: token1
            } = token_pair,
          price: token_pair_dex_price,
          address: token_pair_dex_address
        } =
          token_pair_dex
      ) do
    profitable_trades_result =
      with {:ok, other_token_pair_dexs} <- TPDC.extract_other_token_pair_dexs(token_pair, dex) do
        other_token_pair_dexs
        |> Enum.reduce([], fn token_pair_dex_searched, acc ->
          ## TODO create a function that pass token_pair_dex and token_pair_dex_searched to see if its profitable

          {:ok,
           %TokenPairDex{price: token_pair_dex_searched_price, dex: %Dex{name: dex_searched_name}} =
             token_pair_dex_searched} =
            TPDC.update_token_pair_dex_price(token_pair_dex_searched)

          price_difference =
            Compute.calculate_difference(
              token_pair_dex_price,
              token_pair_dex_searched_price
            )
        end)

        ###### broken from below

        list_dex
        |> Enum.reduce([], fn dex_name_searched, acc ->
          case profitable_trade_from_dex(
                 LD.token_pair_from_list_dex(
                   ConCache.get(:dex, dex_name_searched),
                   token_pair_dex
                 )
               ) do
            {true, token_pair_searched} ->
              {:ok, updated_token_pair_searched} =
                LD.update_token_pair_price(
                  token_pair_searched,
                  dex_name_searched,
                  Compute.calculate_price(token_pair_searched["address"])
                )

              price_difference =
                Compute.calculate_difference(
                  updated_token_pair_searched["price"],
                  token_pair_dex["price"]
                )

              case is_trade_profitable?(
                     price_difference,
                     dex_name,
                     token_pair_dex,
                     dex_name_searched,
                     updated_token_pair_searched
                   ) do
                {:ok, false, _price_difference_result, _estimated_profit,
                 _simulated_profit_token_symbol, _tradable_amount, _gas_fee} ->
                  acc

                {:ok, direction, true, estimated_profit, simulated_profit_token_symbol,
                 tradable_amount, gas_fee} ->
                  acc ++
                    [
                      {token_pair_dex, updated_token_pair_searched, dex_name, dex_name_searched,
                       estimated_profit, simulated_profit_token_symbol, direction,
                       tradable_amount, gas_fee}
                    ]

                {:ok, _direction, false, _estimated_profit, _simulated_profit_token_symbol,
                 _tradable_amount, _gas_fee} ->
                  acc

                _ ->
                  %{
                    token_content: token_pair_dex,
                    token_searched: updated_token_pair_searched
                  }
                  |> LogWritter.ipt("output: error in is_trade_profitable? for those tokens")

                  acc
              end

            false ->
              acc
          end
        end)
      end

    {:ok, profitable_trades_result}
    |> LogWritter.ipt("sx1 get_profitable_trades result")
  end

  # def get_profitable_trade(
  #       %TokenPairDex{
  #         dex:
  #           %Dex{
  #             name: dex_name
  #           } = dex,
  #         token_pair: %TokenPair{}
  #       } =
  #         token_pair_dex
  #     ) do
  #   # with list_dex <-
  #   #        ConCache.get(:dex, "list_dex")
  #   #        |> Enum.filter(fn list_dex_name -> list_dex_name != dex_name end) do
  #   profitable_trades_result =
  #     with list_dex <- DS.with_not_name(dex_name) |> Repo.all() do
  #       list_dex
  #       |> Enum.reduce([], fn dex_name_searched, acc ->
  #         case profitable_trade_from_dex(
  #                LD.token_pair_from_list_dex(
  #                  ConCache.get(:dex, dex_name_searched),
  #                  token_pair_dex
  #                )
  #              ) do
  #           {true, token_pair_searched} ->
  #             {:ok, updated_token_pair_searched} =
  #               LD.update_token_pair_price(
  #                 token_pair_searched,
  #                 dex_name_searched,
  #                 Compute.calculate_price(token_pair_searched["address"])
  #               )

  #             price_difference =
  #               Compute.calculate_difference(
  #                 updated_token_pair_searched["price"],
  #                 token_pair_dex["price"]
  #               )

  #             case is_trade_profitable?(
  #                    price_difference,
  #                    dex_name,
  #                    token_pair_dex,
  #                    dex_name_searched,
  #                    updated_token_pair_searched
  #                  ) do
  #               {:ok, false, _price_difference_result, _estimated_profit,
  #                _simulated_profit_token_symbol, _tradable_amount, _gas_fee} ->
  #                 acc

  #               {:ok, direction, true, estimated_profit, simulated_profit_token_symbol,
  #                tradable_amount, gas_fee} ->
  #                 acc ++
  #                   [
  #                     {token_pair_dex, updated_token_pair_searched, dex_name, dex_name_searched,
  #                      estimated_profit, simulated_profit_token_symbol, direction,
  #                      tradable_amount, gas_fee}
  #                   ]

  #               {:ok, _direction, false, _estimated_profit, _simulated_profit_token_symbol,
  #                _tradable_amount, _gas_fee} ->
  #                 acc

  #               _ ->
  #                 %{
  #                   token_content: token_pair_dex,
  #                   token_searched: updated_token_pair_searched
  #                 }
  #                 |> LogWritter.ipt("output: error in is_trade_profitable? for those tokens")

  #                 acc
  #             end

  #           false ->
  #             acc
  #         end
  #       end)
  #     end

  #   {:ok, profitable_trades_result}
  #   |> LogWritter.ipt("sx1 get_profitable_trades result")
  # end

  def profitable_trade_from_dex(%{"address" => _address} = token_pair_searched),
    do: {true, token_pair_searched}

  def profitable_trade_from_dex(%{}), do: false

  def is_trade_profitable?(
        0,
        _dex_name,
        _is_trade_profitable,
        _dex_name_searched,
        _updated_token_pair_searched
      ),
      do: {false, 0}

  def is_trade_profitable?(
        _price_difference,
        dex_name,
        token_pair_dex,
        dex_name_searched,
        token_pair_searched
      ) do
    with router_address <-
           @dexs[dex_name]["router"]
           |> LogWritter.ipt("sx1 router_address"),
         router_address_searched <-
           @dexs[dex_name_searched]["router"]
           |> LogWritter.ipt("sx1 router_address_searched"),
         {:ok, [reserve0, reserve1, _block_timestamp_last]} <-
           token_pair_dex["address"]
           |> LogWritter.ipt("sx1 pair_address")
           |> contract(:get_reserves)
           |> LogWritter.ipt("sx1 get_reserves pair_address_dex_name"),
         {:ok, [reserve0_searched, reserve1_searched, _block_timestamp_last]} <-
           token_pair_searched["address"]
           |> contract(:get_reserves)
           |> LogWritter.ipt("sx1 get_reserves pair_address_dex_name_searched"),
         content_pair_price_O_I <-
           (reserve0 / reserve1)
           |> LogWritter.ipt("sx1 content_pair_price"),
         searched_pair_price_O_I <-
           (reserve0_searched / reserve1_searched)
           |> LogWritter.ipt("sx1 searched_pair_price"),
         {:ok, direction, _difference_pair_price_O_I} <-
           transaction_direction(searched_pair_price_O_I - content_pair_price_O_I)
           |> LogWritter.ipt("sx1 transaction_direction"),
         {:ok, simulated_profit_pre_gas, tradable_amount} <-
           simulate_profit_pre_gas(
             router_address,
             reserve0,
             reserve1,
             router_address_searched,
             reserve0_searched,
             reserve1_searched,
             token_pair_dex,
             direction
           )
           |> LogWritter.ipt("sx1 simulate_profit_pre_gas"),
         {:ok, gas_fee, simulated_profit_token_symbol} <-
           calculate_gas_price_for_trade(token_pair_dex["token1"])
           |> LogWritter.ipt("sx1 gas_fee in token1 amount"),
         simulated_profit <-
           (simulated_profit_pre_gas - gas_fee)
           |> LogWritter.ipt("sx1 simulated_profit") do
      {:ok, direction, simulated_profit > 0, simulated_profit, simulated_profit_token_symbol,
       tradable_amount, gas_fee}
    end
  end

  def test() do
    {:ok, address} =
      "0x2b561b3f99f2a872c4485c61aeec1e935a1968c6"
      |> contract(:token0)
      |> IO.inspect(label: "sx1 get_reserves pair_address_dex_name_searched")

    address
    |> contract(:symbol)
    |> IO.inspect(label: "sx1 get_reserves symbol")

    address
    |> contract(:decimals)
    |> IO.inspect(label: "sx1 get_reserves decimal")

    # :init.restart()
  end

  def calculate_gas_price_for_trade(%{"symbol" => "WETH"}),
    do: {:ok, ConCache.get(:gas, :estimated_gas_fee), "WETH"}

  def calculate_gas_price_for_trade(profit_token) do
    with estimated_gas_fee <- ConCache.get(:gas, :estimated_gas_fee),
         {:ok, gas_token_pair} <-
           Compute.get_pair_address(
             "0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f",
             "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2",
             profit_token["address"]
           ),
         {:ok, weth_location} <- locate_weth_in_token_pair(gas_token_pair),
         {:ok, [reserve0, reserve1, _block_timestamp]} <-
           gas_token_pair |> contract(:get_reserves),
         {:ok, unit_weth_token_profit_price} <-
           calculate_gas_price_weth_price(weth_location, reserve0, reserve1) do
      {:ok, unit_weth_token_profit_price * estimated_gas_fee, profit_token["symbol"]}
    end
  end

  def calculate_gas_price_weth_price(:token0_weth, reserve0, reserve1),
    do: {:ok, reserve1 / (reserve0 * 1_000_000_000)}

  def calculate_gas_price_weth_price(:token1_weth, reserve0, reserve1),
    do: {:ok, reserve0 / (reserve1 * 1_000_000_000)}

  def locate_weth_in_token_pair(%{"token0" => %{"symbol" => "WETH"}}), do: {:ok, :token0_weth}
  def locate_weth_in_token_pair(%{"token1" => %{"symbol" => "WETH"}}), do: {:ok, :token1_weth}
  def locate_weth_in_token_pair(_), do: {:error, "WETH not find in token_pair"}

  def transaction_direction(pre_direction_gas_price_difference)
      when pre_direction_gas_price_difference < 0,
      do: {:ok, :O_I, pre_direction_gas_price_difference * -1}

  def transaction_direction(pre_gas_direction_price_difference)
      when pre_gas_direction_price_difference > 0,
      do: {:ok, :I_O, pre_gas_direction_price_difference}

  def transaction_direction(0), do: {:ok, false, 0}

  def simulate_profit_pre_gas(
        router_address,
        reserve0,
        reserve1,
        router_address_searched,
        reserve0_searched,
        reserve1_searched,
        token_pair,
        :I_O
      ) do
    IO.puts("sx1 in simulate_profit_pre_gas :I_0")
    reserve0 |> LogWritter.ipt("sx1 reserve0 value")

    with {:ok, estimate} <-
           router_address_searched
           |> estimate_extractor(
             reserve0,
             token_pair["token1"]["address"],
             token_pair["token0"]["address"],
             4
             #  18
           )
           |> LogWritter.ipt("sx1 estimate :I_0"),
         {:ok, result} <-
           router_address
           |> simulate_amounts_output(
             estimate |> Enum.at(1),
             token_pair["token0"]["address"],
             token_pair["token1"]["address"]
           )
           |> LogWritter.ipt("sx1 result"),
         {:ok, amount_in, amount_out} <-
           simulate(estimate |> Enum.at(0), router_address_searched, router_address, token_pair),
         pre_direction_gas_price_difference <-
           (amount_out - amount_in)
           |> LogWritter.ipt("sx1 pre_direction_gas_price_difference :I_O") do
      {:ok, pre_direction_gas_price_difference, amount_in}
    end
  end

  def simulate_profit_pre_gas(
        router_address,
        reserve0,
        reserve1,
        router_address_searched,
        reserve0_searched,
        reserve1_searched,
        token_pair,
        :O_I
      ) do
    IO.puts("sx1 in simulate_profit_pre_gas :0_I")
    reserve0_searched |> LogWritter.ipt("sx1 reserve0_searched value")

    with {:ok, estimate} <-
           router_address
           |> estimate_extractor(
             reserve0_searched,
             token_pair["token1"]["address"],
             token_pair["token0"]["address"],
             4
             #  18
           )
           |> LogWritter.ipt("sx1 estimate :0_I"),
         {:ok, result} <-
           router_address_searched
           |> simulate_amounts_output(
             estimate |> Enum.at(1),
             token_pair["token0"]["address"],
             token_pair["token1"]["address"]
           )
           |> LogWritter.ipt("sx1 result"),
         {:ok, amount_in, amount_out} <-
           simulate(estimate |> Enum.at(0), router_address, router_address_searched, token_pair),
         pre_direction_gas_price_difference <-
           (amount_out - amount_in)
           |> LogWritter.ipt("sx1 pre_direction_gas_price_difference :O_I") do
      {:ok, pre_direction_gas_price_difference, amount_in}
    end
  end

  def safety_tradable_amount(reserve0, reserve1),
    do: if(reserve0 > reserve1, do: {:ok, reserve1}, else: {:ok, reserve0})

  def estimate_extractor(router, amount, token0, token1, counter) when counter <= 0,
    do: {:error, "event not tradable"}

  def estimate_extractor(router, amount, token0, token1, counter) do
    list_divider = [
      1_000_000_000_000,
      1_000_000,
      1000,
      100,
      2
    ]

    # list_divider = [
    #   1_000_000_000_000,
    #   500_000_000_000,
    #   1_000_000_000,
    #   500_000_000,
    #   1_000_000,
    #   500_000,
    #   1000,
    #   500,
    #   100,
    #   50,
    #   10,
    #   9,
    #   8,
    #   7,
    #   6,
    #   5,
    #   4,
    #   3,
    #   2
    # ]

    with divider <- list_divider |> Enum.at(counter) |> trunc(),
         min_amount <- (amount / divider) |> trunc(),
         {:ok, estimate} <-
           router
           |> simulate_amounts_input(
             min_amount,
             token0,
             token1
           ) do
      {:ok, estimate}
    else
      {:error,
       %{
         "code" => _code,
         "data" => _data,
         "message" => "execution reverted: ds-math-sub-underflow"
       }} ->
        estimate_extractor(router, amount, token0, token1, counter - 2)

      {:error,
       %{
         "code" => _code,
         "data" => _data,
         "message" => "execution reverted: UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT"
       }} ->
        estimate_extractor(router, amount, token0, token1, counter + 1)
    end
  end
end
