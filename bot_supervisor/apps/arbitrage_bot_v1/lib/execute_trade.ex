defmodule ExecuteTrade do
  @dexs Libraries.dexs()

  def run([]),
    do: IO.puts("sx1 no profitable trades to execute")

  def run(list_profitable_trades) when is_list(list_profitable_trades) do
    with {:ok, eth_wallet_amount} <- Compute.get_wallet_balance() do
      list_profitable_trades
      |> Enum.sort_by(
        fn {token_pair_content, updated_token_pair_searched, dex_name, dex_name_searched,
            estimated_profit, simulated_profit_token_symbol, direction, tradable_amount,
            gas_fee} ->
          estimated_profit
        end,
        :desc
      )
      |> Enum.reduce_while([], fn trade, acc ->
        IO.puts("sx1 inside reduce_while")
        case maybe_execute_trade(trade, eth_wallet_amount) do
          {:error, trade} ->
            trade |> LogWritter.ipt("sx1 trade failed to execute, continuing to next trade...")
            {:cont, acc}
          {:ok, trade} -> {:halt, trade}
        end
      end)
      |> LogWritter.ipt("sx1 execute trade result")
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

    # Compute.execute_trade(
    #   token1,
    #   token0,
    #   dex_content_address,
    #   dex_searched_address,
    #   tradable_amount
    # )
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
    with {:ok, true} <- enough_eth_to_pay_gas_fee?(gas_fee, eth_wallet_amount) |> LogWritter.ipt("sx1 enough_eth_to_pay_gas_fee?"),
         dex_content_address <- @dexs |> Map.get(dex_name) |> Map.get("router"),
         dex_searched_address <- @dexs |> Map.get(dex_name_searched) |> Map.get("router"),
         {:ok, trade_result} <-
           execute_trade(
             token_pair_content["token0"]["address"]
             |> LogWritter.ipt("sx1 token_pair_content[token0][address]"),
             token_pair_content["token1"]["address"]
             |> LogWritter.ipt("sx1 token_pair_content[token1][address]"),
             dex_content_address |> LogWritter.ipt("sx1 dex_content_address"),
             dex_searched_address |> LogWritter.ipt("sx1 dex_searched_address"),
             tradable_amount |> LogWritter.ipt("sx1 tradable_amount"),
             direction |> LogWritter.ipt("sx1 direction")
           ) do
      eth_wallet_amount
      |> LogWritter.ipt("sx1 eth_wallet_amount before")

      {:ok, eth_wallet_amount_after} =
        Compute.get_wallet_balance()
        |> LogWritter.ipt("sx1 eth_wallet_amount after")

      (eth_wallet_amount_after - eth_wallet_amount)
      |> LogWritter.ipt("sx1 Gain / Lost")

      System.get_env("ACCOUNT_NUMBER")
      |> LogWritter.ipt("sx1 ACCOUNT_NUMBER")

      {:ok, weth_amount} =
        Compute.get_weth_balance(System.get_env("ACCOUNT_NUMBER"))
        |> LogWritter.ipt("sx1 weth_amount?")

      {:ok, weth_total_supply} =
        Compute.weth_total_supply()
        |> LogWritter.ipt("sx1 weth_total_supplymount?")

      {:ok, shib_amount} =
        Compute.get_shib_balance(System.get_env("ACCOUNT_NUMBER"))
        |> LogWritter.ipt("sx1 shib_amount?")

      {:ok,
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
       }}
    else
      msg ->
        {:error,
         {
           msg,
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
         }}
    end
  end

  def enough_eth_to_pay_gas_fee?(gas_fee, eth_wallet_amount) do
    eth_wallet_amount |> LogWritter.ipt("sx1 eth_wallet_amount")
    gas_fee |> LogWritter.ipt("sx1 gas_fee")

    {:ok, eth_wallet_amount > gas_fee}
  end
end
