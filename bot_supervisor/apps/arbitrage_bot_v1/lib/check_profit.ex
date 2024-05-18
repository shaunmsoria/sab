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

              case profitable_trade_from_dex(LD.token_pair_from_list_dex(ConCache.get(:dex, dex_name_searched), token_pair_content)) do
                {:true, token_pair_searched} ->

                  {:ok, updated_token_pair_searched} = LD.update_token_pair_price(token_pair_searched, dex_name_searched, Compute.calculate_price(token_pair_searched["address"]))

                  price_difference = Compute.calculate_difference(updated_token_pair_searched["price"], token_pair_content["price"])

                  case is_trade_profitable?(price_difference, dex_name, token_pair_content, dex_name_searched, updated_token_pair_searched) do
                    {false, _price_difference_result} -> acc

                    {direction, true} -> acc ++ [{token_pair_content, updated_token_pair_searched, dex_name, dex_name_searched, price_difference, direction}]

                    {_direction, false} -> acc
                  end


                false -> acc
              end
            end)

    end
    {:ok, profitable_trades_result}
  end


  def profitable_trade_from_dex(%{"address" => _address} = token_pair_searched), do: {:true, token_pair_searched}
  def profitable_trade_from_dex(%{}), do: false

  def is_trade_profitable?(0, _dex_name, _is_trade_profitable, _dex_name_searched, _updated_token_pair_searched), do: false
  def is_trade_profitable?(
    _price_difference,
    dex_name,
    token_pair_content,
    dex_name_searched,
    token_pair_searched) do
      with  estimated_gas_fee <- ConCache.get(:gas, :estimated_gas_fee) |> IO.inspect(label: "sx0 estimated_gas_fee"),
      factory_address <- @dexs[dex_name]["factory"],
      factory_address_searched <- @dexs[dex_name_searched]["factory"],
        {:ok, pair_address_dex_name} <- Compute.get_pair_address(factory_address, token_pair_content.address, token_pair_searched.address),
        {:ok, pair_address_dex_name_searched} <- Compute.get_pair_address(factory_address_searched, token_pair_content.address, token_pair_searched.address),
        {:ok, [reserve0, reserve1, _block_timestamp_last]} <- pair_address_dex_name |> contract(:get_reserves),
        {:ok, [reserve0_searched, reserve1_searched, _block_timestamp_last]} <- pair_address_dex_name_searched |> contract(:get_reserves),
        {:ok, simulated_amount_out_reserve_1} <- factory_address |> simulate_amount_output(reserve0_searched, reserve0, reserve1),
        {:ok, simulated_amount_out_reserve_0} <- factory_address_searched |> simulate_amount_output(simulated_amount_out_reserve_1, reserve0_searched, reserve1_searched),
        pre_direction_gas_price_difference <- simulated_amount_out_reserve_0 - reserve0_searched,
        {direction, pre_gas_difference} <- transaction_direction(pre_direction_gas_price_difference),
        simulated_price_difference <- pre_gas_difference - estimated_gas_fee do


          {direction, simulated_price_difference > 0}

      end
    true
  end

  def transaction_direction(pre_direction_gas_price_difference) when pre_direction_gas_price_difference > 0, do: {:origin_to_search, pre_direction_gas_price_difference}
  def transaction_direction(pre_gas_direction_price_difference) when pre_gas_direction_price_difference < 0, do: {:origin_to_search, pre_gas_direction_price_difference * -1}
  def transaction_direction(0), do: {false, 0}

end
