defmodule ExecuteTrade do
  alias ProfitableTradeContext, as: PTC
  alias LogWritter, as: LW

  @dexs Libraries.dexs()

  def run_v2([]),
    do: IO.puts("sx1 no profitable trades to execute")

  def run_v2(list_profitable_trades) when is_list(list_profitable_trades) do
    with {:ok, eth_wallet_amount} <- Compute.get_wallet_balance() do
      list_profitable_trades
      |> Enum.sort_by(
        fn %ProfitableTrade{estimated_profit: estimated_profit} ->
          estimated_profit
        end,
        :desc
      )
      |> Enum.reduce_while([], fn trade, acc ->
        case maybe_execute_trade_v2(trade, eth_wallet_amount) do
          {:error, trade} ->
            trade |> LogWritter.ipt("sx1 trade failed to execute, continuing to next trade...")
            {:cont, acc}

          {:ok, trade} ->
            {:halt, trade}
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
        "O_I"
      ) do
    Compute.execute_trade(
      token1,
      token0,
      dex_content_address,
      dex_searched_address,
      String.to_integer(tradable_amount)
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
        "I_O"
      ) do
    Compute.execute_trade(
      token1,
      token0,
      dex_searched_address,
      dex_content_address,
      String.to_integer(tradable_amount)
    )
  end

  def maybe_execute_trade_v2(
        %ProfitableTrade{
          id: profitable_trade_id,
          token_pair:
            %TokenPair{
              token0: %Token{
                address: token0_address
              },
              token1: %Token{
                address: token1_address
              }
            } = token_pair,
          dex_emitted:
            %Dex{
              router: dex_emitted_router_address
            } = dex_emitted,
          dex_searched:
            %Dex{
              router: dex_searched_router_address
            } = dex_searched,
          token_profit: token_profit,
          estimated_profit: estimated_profit,
          direction: direction,
          tradable_amount: tradable_amount,
          gas_fee: gas_fee,
          smart_contract_response: sc_response
        } = profitable_trade,
        eth_wallet_amount
      ) do
    with {:ok, true} <-
           enough_eth_to_pay_gas_fee?(gas_fee, eth_wallet_amount),
         {:ok, trade_result} <-
           execute_trade(
             token0_address,
             token1_address,
             dex_emitted_router_address,
             dex_searched_router_address,
             tradable_amount,
             direction
           ) do

            trade_result |> LW.ipt("sx1 trade_result")
      PTC.update(profitable_trade, %{smart_contract_response: inspect(trade_result)})
    else
      msg ->
        {:ok, profitable_trade} =
          PTC.update(profitable_trade, %{smart_contract_response: inspect(msg)})

        {:error, profitable_trade}
    end
  end

  def enough_eth_to_pay_gas_fee?(gas_fee, eth_wallet_amount) do
    eth_wallet_amount |> LogWritter.ipt("sx1 eth_wallet_amount")
    gas_fee |> LogWritter.ipt("sx1 gas_fee")

    {:ok, eth_wallet_amount > String.to_float(gas_fee)}
  end
end
