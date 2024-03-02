defmodule CheckProfit do
  import Compute

  # @dexs Libraries.dexs()
  # @tokens Libraries.tokens()


  def run(event_raw) when is_map(event_raw) do

    event_raw.event.address
    |> calculate_price()
    |> IO.inspect(label: "sx1 price")

    event_raw.event.address
    |> IO.inspect(label: "sx1 address")

  end

end
