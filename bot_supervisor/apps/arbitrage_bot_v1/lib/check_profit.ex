defmodule CheckProfit do
  import Compute
  alias ListDex, as: LD

  @dexs Libraries.dexs()

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
                    {:ok, false, _price_difference_result, _estimated_profit} ->
                      acc

                    {:ok, direction, true, estimated_profit} ->
                      acc ++ [{token_pair_content, updated_token_pair_searched, dex_name, dex_name_searched, estimated_profit, direction}]

                    {:ok, _direction, false, _estimated_profit} ->
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
      token_pair_searched |> IO.inspect(label: "mx1 token_pair_searched")

      with  estimated_gas_fee <- ConCache.get(:gas, :estimated_gas_fee) |> IO.inspect(label: "sx0 estimated_gas_fee"),
      router_address <- @dexs[dex_name]["router"] |> IO.inspect(label: "sx1 router_address"),
      router_address_searched <- @dexs[dex_name_searched]["router"] |> IO.inspect(label: "sx1 router_address_searched"),
        {:ok, [reserve0, reserve1, _block_timestamp_last]} <- token_pair_content["address"] |> contract(:get_reserves) |> IO.inspect(label: "sx0 get_reserves pair_address_dex_name"),
        {:ok, [reserve0_searched, reserve1_searched, _block_timestamp_last]} <- token_pair_searched["address"] |> contract(:get_reserves) |> IO.inspect(label: "sxo get_reserves pair_address_dex_name_searched"),
        {:ok, simulated_amount_out_reserve_0} <- router_address |> simulate_amount_output(reserve1_searched, reserve0, reserve1) |> IO.inspect(label: "sx1 simulate_amount_output content"),
        {:ok, simulated_amount_out_reserve_1} <- router_address_searched |> simulate_amount_output(simulated_amount_out_reserve_0, reserve0_searched, reserve1_searched) |> IO.inspect(label: "sx1 simulate_amount_output searched"),
        pre_direction_gas_price_difference <- simulated_amount_out_reserve_1 - reserve1_searched,
        {:ok, direction, pre_gas_difference} <- transaction_direction(pre_direction_gas_price_difference),
        simulated_profit <- pre_gas_difference - estimated_gas_fee do


          {:ok, direction, simulated_profit > 0, simulated_profit}

      end
  end

  def calculate_gas_price_for_trade(%{"symbol" => "WETH"} = profit_token), do: estimated_gas_fee <- ConCache.get(:gas, :estimated_gas_fee) |> IO.inspect(label: "sx0 estimated_gas_fee")
  def calculate_gas_price_for_trade(profit_token) do
    with estimated_gas_fee <- ConCache.get(:gas, :estimated_gas_fee) |> IO.inspect(label: "sx0 estimated_gas_fee"),
    {:ok, gas_token_pair} <- Compute.get_pair_address(
      "0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f",
      "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2",
      profit_token.address
    ) do

    end
  end

  def locate_weth_in_token_pair()

  def transaction_direction(pre_direction_gas_price_difference) when pre_direction_gas_price_difference > 0, do: {:ok, :origin_to_search, pre_direction_gas_price_difference}
  def transaction_direction(pre_gas_direction_price_difference) when pre_gas_direction_price_difference < 0, do: {:ok, :search_to_origin, pre_gas_direction_price_difference * -1}
  def transaction_direction(0), do: {:ok, false, 0}

end
