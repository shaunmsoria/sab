defmodule CheckProfit do
  import Compute
  alias ListDex, as: LD

  def run(state, event_data) when is_map(event_data) do
    with  price <- calculate_price(event_data.event.address) |> IO.inspect(label: "sx1 price"),
          address <- event_data.event.address |> IO.inspect(label: "sx1 address"),
          {:ok, {token_pair, dex_name}} <- found_dex_token_pair?(address),
          {:ok, token_pair_price_udpated} <- LD.update_token_pair_price(token_pair, dex_name, price),
          {:ok, list_of_profitable_trades} <- get_profitable_trade(token_pair, dex_name) do

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
    token_pair_content |> IO.inspect(label: "sx1 token_pair_address")
    dex_name |> IO.inspect(label: "sx1 dex_name")


    with {_address, dex} <- ConCache.get(:dex, dex_name),
          dex_price <- dex["price"],
          list_dex <- ConCache.get(:dex, "list_dex"),
           do

            list_dex
            |> Enum.reduce([], fn dex_name, acc ->
              if profitable_trade_from_dex(
              LD.token_pair_from_list_dex(
              ConCache.get(:dex, dex_name),
                token_pair_content)) == {:true, token_pair_searched} do
            {:ok, updated_token_pair_searched} = LD.update_token_pair_price(token_pair_searched, dex_name, Compute.calculate_price(token_pair_searched["address"]))

                end

              # {:ok, token_pair_price_udpated} = LD.update_token_pair_price(token_pair, dex_name, price)
            end)

            dex_price |> IO.inspect(label: "sx1 dex_price")

    end
    {:ok, ConCache.get(:dex, dex_name) |> Map.get(token_pair_address)}
  end

  def profitable_trade_from_dex(%{}), do: false

  def profitable_trade_from_dex({_address, token_pair_searched}), do: {:true, token_pair_searched}



end
