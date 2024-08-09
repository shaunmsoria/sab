defmodule ExecuteTrade do
  @dexs Libraries.dexs()

  def run([]),
    do: IO.puts("sx1 no profitable trades to execute")

  def run(list_profitable_trades) when is_list(list_profitable_trades) do
    with {:ok, eth_wallet_amount} <- Compute.get_wallet_balance() do
      list_profitable_trades
      |> Enum.map(fn trade ->
        maybe_execute_trade(trade, eth_wallet_amount)
      end)
      |> IO.inspect(label: "sx1 list_profitable_trades")
    end
  end

  def execute_trade(
        token0,
        token1,
        dex_content_address,
        dex_searched_address,
        tradable_amount,
        :O_I
      ) do
    Compute.execute_trade(
      token1,
      token0,
      dex_content_address,
      dex_searched_address,
      tradable_amount
    )
  end

  def execute_trade(
        token0,
        token1,
        dex_content_address,
        dex_searched_address,
        tradable_amount,
        :I_O
      ) do
    Compute.execute_trade(
      token1,
      token0,
      dex_searched_address,
      dex_content_address,
      tradable_amount
    )
  end

  def maybe_execute_trade(
        {
          token_pair_content,
          updated_token_pair_searched,
          dex_name,
          dex_name_searched,
          estimated_profit,
          simulated_profit_token_symbol,
          direction,
          tradable_amount,
          gas_fee
        },
        eth_wallet_amount
      ) do
    with {:ok, true} <- enough_eth_to_pay_gas_fee?(gas_fee, eth_wallet_amount),
         dex_content_address <- @dexs |> Map.get(dex_name) |> Map.get("router"),
         dex_searched_address <- @dexs |> Map.get(dex_name_searched) |> Map.get("router"),
         {:ok, trade_result} <-
           execute_trade(
             token_pair_content["token0"]["address"]
             |> IO.inspect(label: "sx1 token_pair_content[token0][address]"),
             token_pair_content["token1"]["address"]
             |> IO.inspect(label: "sx1 token_pair_content[token1][address]"),
             dex_content_address |> IO.inspect(label: "sx1 dex_content_address"),
             dex_searched_address |> IO.inspect(label: "sx1 dex_searched_address"),
             tradable_amount |> IO.inspect(label: "sx1 tradable_amount"),
             direction |> IO.inspect(label: "sx1 direction")
           ) do
      eth_wallet_amount
      |> IO.inspect(label: "sx1 eth_wallet_amount before")

      {:ok, eth_wallet_amount_after} =
        Compute.get_wallet_balance()
        |> IO.inspect(label: "sx1 eth_wallet_amount after")

      (eth_wallet_amount_after - eth_wallet_amount)
      |> IO.inspect(label: "sx1 Gain / Lost")

      {:ok, weth_amount} =
        Compute.get_weth_balance(System.get_env("ACCOUNT_NUMBER"))
        |> IO.inspect(label: "sx1 weth_amount?")

      {
        trade_result,
        token_pair_content,
        updated_token_pair_searched,
        dex_name,
        dex_name_searched,
        estimated_profit,
        simulated_profit_token_symbol,
        direction,
        tradable_amount,
        gas_fee,
        eth_wallet_amount
      }
    else
      _ ->
        {
          "not_enough_eth_to_pay_for_gas_fees",
          token_pair_content,
          updated_token_pair_searched,
          dex_name,
          dex_name_searched,
          estimated_profit,
          simulated_profit_token_symbol,
          direction,
          tradable_amount,
          gas_fee,
          eth_wallet_amount
        }
    end
  end

  def enough_eth_to_pay_gas_fee?(gas_fee, eth_wallet_amount),
    do: {:ok, eth_wallet_amount > gas_fee}
end
