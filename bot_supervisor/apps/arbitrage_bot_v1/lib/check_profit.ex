defmodule CheckProfit do
  import Compute
  alias ListDex, as: LD

  # @dexs Libraries.dexs()
  # @tokens Libraries.tokens()


  def run(state, event_data) when is_map(event_data) do

    _price =
      event_data.event.address
      |> calculate_price()
      |> IO.inspect(label: "sx1 price")

    address =
      event_data.event.address
      |> IO.inspect(label: "sx1 address")

    _list_dex =
    state
    |> LD.get_dex_token_pair_from_address(address)
    |> IO.inspect(label: "sx1 list_dex")



    with {:ok, token_pair} <- found_dex_token_pair?(state, address),
        {:ok, list_of_profitable_trades} <- get_profitable_trades(state, token_pair) do
        list_of_profitable_trades
        |> IO.inspect(label: "sx1 list_of_profitable_trades")
        else
          error ->
            error |> IO.inspect(label: "sx1 found")
    end


  end

  def found_dex_token_pair?(state, address) do
    token_pair = LD.get_dex_token_pair_from_address(state, address)

    if (token_pair != %{}), do: {:ok, token_pair}, else: {:error, "no token_pair found"}
  end

  def get_profitable_trades(state, token_pair) do
    state
    |> Enum.reduce([], fn list_dex, acc ->
      list_dex.name
      |> IO.inspect(label: "sx1 list_dex.name")

      token_pairs =
      LD.get_token_pair_from_token_ids(list_dex.list, token_pair)
      IO.puts("sx1 after get_token_pair_from_token_ids")

      if (token_pairs == %{}), do: acc, else: acc ++ [%{dex: list_dex.name, token_pair: token_pair}]
    end)
    |> found_profitable_trades()

  end

  def found_profitable_trades([]), do: {:error, "no profitable trades found"}
  def found_profitable_trades(list_of_trades) when is_list(list_of_trades),
      do: {:ok, list_of_trades}



end
