defmodule ExecuteTrade do
  def maybe_execute_trade([]),
   do: IO.puts("sx1 no profitable trades to execute")


  def maybe_execute_trade(list_profitable_trades) when is_list(list_profitable_trades) do

    with  {:ok, eth_wallet_amount} <- Compute.get_wallet_balance() do

      list_profitable_trades |> IO.inspect(label: "sx1 list_profitable_trades")

    end
  end
end
