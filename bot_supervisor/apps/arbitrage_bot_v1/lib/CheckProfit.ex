defmodule CheckProfit do
  import Compute

  @dexs Libraries.dexs()
  @tokens Libraries.tokens()


  def run(address, data) when is_binary(address) and is_map(data) do
    address
    |> calculate_price()
    |> IO.inspect(label: "sx1 price")

  end

end
