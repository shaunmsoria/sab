defmodule CheckProfit do
  import Compute
  alias ListDex, as: LD

  @dexs Libraries.dexs()
  @balancer Libraries.balancer()

  def run(_state, event_data) when is_map(event_data) do
    with  price <- calculate_price(event_data.event.address) |> IO.inspect(label: "sx1 price"),
          address <- event_data.event.address |> IO.inspect(label: "sx1 address"),
          {:ok, {token_pair, dex_name}} <- found_dex_token_pair?(address),
          {:ok, token_pair_price_udpated} <- LD.update_token_pair_price(token_pair, dex_name, price),
          {:ok, list_of_profitable_trades} <- get_profitable_trade(token_pair_price_udpated, dex_name) do

      list_of_profitable_trades
      |> IO.inspect(label: "sx1 list_of_profitable_trades")
    else
      error ->
        error |> IO.inspect(label: "sx1 error:")
    end
  end

  def found_dex_token_pair?(address) do
    with {:ok, token_pair} <- LD.get_dex_token_pair_from_address(address) do
      {:ok, token_pair}
    else
      _ -> {:error, "no token_pair found"}
    end
  end

  def update_token_pair_price(token_pair, dex_name, price) do
    with :ok <- ConCache.update(:dex, dex_name,
    fn dex_content ->
      {:ok, %{dex_content | token_pair["address"] => %{token_pair | "price" => price}}}
    end) do

    {:ok, ConCache.get(:dex, dex_name) |> Map.get(token_pair["address"])}

    end
  end

  ## TODO
  def get_profitable_trade(token_pair_content, dex_name) do

    profitable_trades_result =
    with  list_dex <-
      ConCache.get(:dex, "list_dex")
      |> Enum.filter(fn list_dex_name -> list_dex_name != dex_name end) do

            list_dex
            |> Enum.reduce([], fn dex_name_searched, acc ->

              case profitable_trade_from_dex(
                LD.token_pair_from_list_dex(
                  ConCache.get(:dex, dex_name_searched),
                  token_pair_content
                )) do

                {:true, token_pair_searched} ->

                  {:ok, updated_token_pair_searched} =
                    LD.update_token_pair_price(
                      token_pair_searched,
                      dex_name_searched,
                      Compute.calculate_price(token_pair_searched["address"])
                    )

                  price_difference = Compute.calculate_difference(updated_token_pair_searched["price"], token_pair_content["price"])

                  case is_trade_profitable?(price_difference, dex_name, token_pair_content, dex_name_searched, updated_token_pair_searched) do
                    {:ok, false, _price_difference_result, _estimated_profit, _simulated_profit_token_symbol} ->
                      acc

                    {:ok, direction, true, estimated_profit, simulated_profit_token_symbol} ->
                      acc ++ [{token_pair_content, updated_token_pair_searched, dex_name, dex_name_searched, estimated_profit, simulated_profit_token_symbol, direction}]

                    {:ok, _direction, false, _estimated_profit, _simulated_profit_token_symbol} ->
                      acc

                    _ ->
                      %{token_content: token_pair_content, token_searched: updated_token_pair_searched}
                      |> IO.inspect(label: "output: error in is_trade_profitable? for those tokens")

                      acc
                  end


                false -> acc
              end
            end)

    end
    {:ok, profitable_trades_result}
    |> IO.inspect(label: "sx1 get_profitable_trades result")
  end


  def profitable_trade_from_dex(%{"address" => _address} = token_pair_searched), do: {:true, token_pair_searched}
  def profitable_trade_from_dex(%{}), do: false

  def is_trade_profitable?(0, _dex_name, _is_trade_profitable, _dex_name_searched, _updated_token_pair_searched), do: {false, 0}
  def is_trade_profitable?(
    _price_difference,
    dex_name,
    token_pair_content,
    dex_name_searched,
    token_pair_searched) do
      token_pair_content |> IO.inspect(label: "mx1 token_pair_content")
      token_pair_content["address"] |> IO.inspect(label: "mx1 token_pair_content[address]")
      token_pair_content["token1"] |> Map.get("address") |> IO.inspect(label: "mx1 token_pair_content[token] |> Map.get(address)")
      token_pair_content["token1"]["address"] |> IO.inspect(label: "mx1 token_pair_content[token1][address]")
      @balancer |> IO.inspect(label: "sx1 @balancer")
      @balancer["pool_address"] |> IO.inspect(label: "sx1 @balancer[pool_address]")
      token_pair_searched |> IO.inspect(label: "mx1 token_pair_searched")

      with router_address <- @dexs[dex_name]["router"] |> IO.inspect(label: "sx1 router_address"),
        router_address_searched <- @dexs[dex_name_searched]["router"] |> IO.inspect(label: "sx1 router_address_searched"),
        {:ok, [reserve0, reserve1, _block_timestamp_last]} <- token_pair_content["address"] |> contract(:get_reserves) |> IO.inspect(label: "sx1 get_reserves pair_address_dex_name"),
        {:ok, [reserve0_searched, reserve1_searched, _block_timestamp_last]} <- token_pair_searched["address"] |> contract(:get_reserves) |> IO.inspect(label: "sx1 get_reserves pair_address_dex_name_searched"),
        {:ok, [cash, managed, last_change_block, asset_manager]} <- @balancer["pool_address"] |> get_pool_token_info_balancer(token_pair_content["token1"]["address"]) |> IO.inspect(label: "sx1 get_pool_token_info result"),
        {:ok, simulated_amount_out_reserve_0} <- router_address |> simulate_amount_output(reserve1_searched, reserve0, reserve1) |> IO.inspect(label: "sx1 simulate_amount_output content"),
        {:ok, simulated_amount_out_reserve_1} <- router_address_searched |> simulate_amount_output(simulated_amount_out_reserve_0, reserve0_searched, reserve1_searched) |> IO.inspect(label: "sx1 simulate_amount_output searched"),
        pre_direction_gas_price_difference <- simulated_amount_out_reserve_1 - reserve1_searched,
        {:ok, direction, pre_gas_difference} <- transaction_direction(pre_direction_gas_price_difference),
        {:ok, gas_fee, simulated_profit_token_symbol} <- calculate_gas_price_for_trade(token_pair_content["token1"]) |> IO.inspect(label: "sx1 gas_fee in token1 amount"),
        simulated_profit <- pre_gas_difference - gas_fee do

          cash |> IO.inspect(label: "sx1 cash")
          managed |> IO.inspect(label: "sx1 managed")
          last_change_block |> IO.inspect(label: "sx1 last_change_block")
          asset_manager |> IO.inspect(label: "sx1 asset_manager")


          {:ok, direction, simulated_profit > 0, simulated_profit, simulated_profit_token_symbol}

      end
  end

  def calculate_gas_price_for_trade(%{"symbol" => "WETH"}), do: {:ok, ConCache.get(:gas, :estimated_gas_fee), "WETH"}
  def calculate_gas_price_for_trade(profit_token) do
    with estimated_gas_fee <- ConCache.get(:gas, :estimated_gas_fee),
    {:ok, gas_token_pair} <- Compute.get_pair_address(
      "0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f",
      "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2",
      profit_token.address
    ),
    {:ok, weth_location} <- locate_weth_in_token_pair(gas_token_pair),
    {:ok, [reserve0, reserve1, _block_timestamp]} <- gas_token_pair |> contract(:get_reserves),
    {:ok, unit_weth_token_profit_price} <- calculate_gas_price_weth_price(weth_location, reserve0, reserve1) do
      {:ok, unit_weth_token_profit_price * estimated_gas_fee, profit_token["symbol"]}
    end
  end

  def calculate_gas_price_weth_price(:token0_weth, reserve0, reserve1), do: {:ok, reserve1 / (reserve0 * 1000000000)}
  def calculate_gas_price_weth_price(:token1_weth, reserve0, reserve1), do: {:ok, reserve0 / (reserve1 * 1000000000)}



  def locate_weth_in_token_pair(%{"token0" => %{"symbol" => "WETH"}}), do: {:ok, :token0_weth }
  def locate_weth_in_token_pair(%{"token1" => %{"symbol" => "WETH"}}), do: {:ok, :token1_weth }
  def locate_weth_in_token_pair(_), do: {:error, "WETH not find in token_pair"}

  def transaction_direction(pre_direction_gas_price_difference) when pre_direction_gas_price_difference > 0, do: {:ok, :origin_to_search, pre_direction_gas_price_difference}
  def transaction_direction(pre_gas_direction_price_difference) when pre_gas_direction_price_difference < 0, do: {:ok, :search_to_origin, pre_gas_direction_price_difference * -1}
  def transaction_direction(0), do: {:ok, false, 0}

end
