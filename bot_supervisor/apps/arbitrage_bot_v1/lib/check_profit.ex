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

    list_dex =
    state
    |> LD.get_list_dex_from_address(address)
    |> IO.inspect(label: "sx1 list_dex")

    with true <- found_dex?(state, list_dex, address) do
      IO.puts("sx1 in the with")
    end


  end

  def found_dex?(state, list_dex, address), do: if state |> LD.get_list_dex_from_address(address) != %{}, do: true, else: false



end
