defmodule ProcessTrade do
  import Compute
  alias ProfitableTradeContext, as: PTC
  alias LogWritter, as: LW
  alias PoolContext, as: PC
  alias PoolV3CheckProfit, as: PV3CP
  alias ProfitableTradeContext, as: PTC

  @dexs Libraries.dexs()

  def run([]),
    do: IO.puts("sx1 no profitable trades to execute")

  ## TODO check if gas in wallet is enough to pay for the gas fee
  def run(potential_profitable_trades) when is_list(potential_profitable_trades) do
    potential_profitable_trades
    |> Enum.reduce_while(false, fn trade, acc ->
      case maybe_execute_trade(trade) do
        false ->
          LW.ipt("sx1 no trade executed")
          {:cont, acc}

        {:error, error} ->
          error |> LW.ipt("sx1 error in maybe_execute_trade")
          {:cont, acc}

        {:ok, msg} ->
          msg |> LW.ipt("sx1 msg in maybe_execute_trade")
          {:halt, true}
      end
    end)
  end

  def maybe_execute_trade(
        {pool_event, pool_searched_raw, _profit_amount, _token_return_symbol, _return_amount,
         burrow_amount, _token_return_amount_for_gas_fee, swap_price_event, swap_direction,
         swap_amount} = params
      ) do
    pool_searched = pool_searched_raw |> Repo.preload([:token_pair, :dex])
    current_pool_price = pool_searched.price

    with {:ok, pool_searched_updated} <- PC.update_pool_price(pool_searched) do
      case current_pool_price == pool_searched_updated.price do
        true ->
          execute_trade(params)

        false ->
          PV3CP.estimate_profitable_pool(
            pool_searched_updated,
            pool_event,
            swap_amount,
            swap_price_event,
            swap_direction
          )
          |> case do
            [] -> false
            [profitable_trade] -> execute_trade(profitable_trade)
          end
      end
    end
  end

  def execute_trade(
        {pool_event, pool_searched, profit_amount, _token_return_symbol, _return_amount,
         burrow_amount, token_return_amount_for_gas_fee, swap_price_event, swap_direction,
         _swap_amount}
      ) do
    %Pool{dex: %Dex{} = dex_event} =
      pool_event |> Repo.preload([:dex, token_pair: [:token0, :token1]])

    %Pool{dex: %Dex{} = dex_searched} =
      pool_searched |> Repo.preload([:dex, token_pair: [:token0, :token1]])

    smart_contract_address =
      System.get_env("CONTRACT_ADDRESS")
      |> IO.inspect(label: "sx1 smart_contract_address")

    token_path =
      token_path_via_direction(
        pool_event.token_pair.token0,
        pool_event.token_pair.token1,
        swap_direction
      )

    profit_decimal_number = pool_event.token_pair.token0.decimals

    data =
      %{
        token_pair: pool_event.token_pair,
        dex_emitted: dex_event,
        dex_searched: dex_searched,
        token_profit: pool_event.token_pair.token0,
        estimated_profit: (profit_amount / 10 ** profit_decimal_number) |> Float.to_string(),
        direction: swap_direction,
        tradable_amount: (burrow_amount / 10 ** profit_decimal_number) |> Float.to_string(),
        gas_fee:
          (token_return_amount_for_gas_fee / 10 ** profit_decimal_number) |> Float.to_string()
        # smart_contract_response: "0x"
      }
      |> LW.ipt("sx1 data test")

    ## TODO check direction for the swap order token0 to token1 or token1 to token0
    Sabv2Contract.execute_trade(
      token_path |> Enum.at(0) |> Map.get(:address),
      token_path |> Enum.at(1) |> Map.get(:address),
      dex_searched.router,
      dex_searched.abi,
      pool_searched.fee |> String.to_integer(),
      dex_event.router,
      dex_event.abi,
      pool_event.fee |> String.to_integer(),
      burrow_amount |> trunc()
    )
    |> IO.inspect(label: "sx1 execute_trade pre Ethers.call()")
    |> Ethers.call(
      to: smart_contract_address,
      gas_limit: 5_000_000,
      value: 0
    )
    |> case do
      {:ok, true} ->
        LW.ipt("Transaction succeeded with true return value")

        updated_data =
          data
          |> Map.merge(%{smart_contract_response: "returned true"})

        PTC.insert(updated_data)
        |> LW.ipt("sx1 PTC.insert")

        {:ok, %{success: true}}

      {:ok, [true]} ->
        LW.ipt("Transaction succeeded with true return value")

        updated_data =
          data
          |> Map.merge(%{smart_contract_response: "returned [true]"})

        PTC.insert(updated_data)
        |> LW.ipt("sx1 PTC.insert")

        {:ok, %{success: true}}

      {:ok, "0x"} ->
        LW.ipt("Transaction succeeded with 0x return value")

        updated_data =
          data
          |> Map.merge(%{smart_contract_response: "returned 0x"})

        PTC.insert(updated_data)
        |> LW.ipt("sx1 PTC.insert")

        {:ok, %{success: true}}

      {:ok, msg} ->
        LW.ipt("Transaction succeeded with unexpected return value: #{inspect(msg)}")

        updated_data =
          data
          |> Map.merge(%{smart_contract_response: "returned #{inspect(msg)}"})

        PTC.insert(updated_data)
        |> LW.ipt("sx1 PTC.insert")

        {:ok, %{success: false, msg: msg}}

      {:error, reason} ->
        LW.ipt("Transaction failed: #{inspect(reason)}")
        {:error, reason}
    end
    |> IO.inspect(label: "sx1 execute_trade post Ethers.call()")
  end

  def token_path_via_direction(%Token{} = token0, %Token{} = token1, "0_1"), do: [token0, token1]
  def token_path_via_direction(%Token{} = token0, %Token{} = token1, "1_0"), do: [token1, token0]
end
