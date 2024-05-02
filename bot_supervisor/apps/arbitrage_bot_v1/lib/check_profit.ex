defmodule CheckProfit do
  import Compute
  alias ListDex, as: LD

  def run(state, event_data) when is_map(event_data) do
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
     gas_limit = System.get_env("GAS_LIMIT") |> IO.inspect(label: "mx1 gas_limit")
     gas_price = System.get_env("GAS_PRICE") |> IO.inspect(label: "mx1 gas_price")
     price_difference = System.get_env("PRICE_DIFFERENCE") |> IO.inspect(label: "mx1 price_difference")

    profitable_trades_result =
    with  list_dex <- ConCache.get(:dex, "list_dex") |> Enum.filter(fn list_dex_name -> list_dex_name != dex_name end) |> IO.inspect(label: "sx1 remove name") do

            list_dex
            |> Enum.reduce([], fn dex_name_searched, acc ->

              case profitable_trade_from_dex(LD.token_pair_from_list_dex(ConCache.get(:dex, dex_name_searched), token_pair_content)) do
                {:true, token_pair_searched} ->

                  {:ok, updated_token_pair_searched} = LD.update_token_pair_price(token_pair_searched, dex_name_searched, Compute.calculate_price(token_pair_searched["address"]))

                  price_difference = Compute.calculate_difference(updated_token_pair_searched["price"], token_pair_content["price"])

                  if price_difference != 0, do: acc ++ [{updated_token_pair_searched, price_difference, dex_name, dex_name_searched}], else: acc


                false -> acc
              end
            end)

    end
    {:ok, profitable_trades_result}
  end


  def profitable_trade_from_dex(%{"address" => _address} = token_pair_searched), do: {:true, token_pair_searched}

  def profitable_trade_from_dex(%{}), do: false


end
