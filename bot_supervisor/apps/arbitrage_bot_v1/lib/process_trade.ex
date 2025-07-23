defmodule ProcessTrade do
  import Compute

  alias Sabv2Contract.EventFilters

  @dexs Libraries.dexs()

  def run([]),
    do: IO.puts("sx1 no profitable trades to execute")

  ## TODO check if gas in wallet is enough to pay for the gas fee
  def run(potential_profitable_trades) when is_list(potential_profitable_trades) do
    potential_profitable_trades
    |> Enum.reduce_while(false, fn trade, acc ->
      case maybe_execute_trade(trade) do
        false ->
          LogWritter.ipt("sx1 no trade executed")
          {:cont, acc}

        {:error, error} ->
          error |> LogWritter.ipt("sx1 error in maybe_execute_trade")
          {:cont, acc}

        {:ok, msg} ->
          msg |> LogWritter.ipt("sx1 msg in maybe_execute_trade")
          {:halt, true}
      end
    end)
  end

  def maybe_execute_trade(
        {pool_event, pool_search_raw, _profit_amount, _token_return, _return_amount,
         burrow_amount, _token_return_amount_for_gas_fee, swap_price_event, swap_direction,
         swap_amount} = params
      ) do
    pool_search = pool_search_raw |> Repo.preload([:token_pair, :dex])
    current_pool_price = pool_search.price

    with {:ok, pool_search_updated} <- PoolContext.update_pool_price(pool_search) do
      swap_amount |> IO.inspect(label: "sx1 swap_amount")
      current_pool_price |> IO.inspect(label: "sx1 current_pool_price")
      pool_search_updated.price |> IO.inspect(label: "sx1 pool_search_updated.price")

      case {swap_amount, current_pool_price == pool_search_updated.price} do
        {-1, _test_result} ->
          IO.puts("sx1 in in -1")
          execute_trade(params)

        {_swap_amount, true} ->
          IO.puts("sx1 in true")
          execute_trade(params)

        {_swap_amount, false} ->
          IO.puts("sx1 in false")

          # PV3CP.estimate_profitable_pool(
          CheckProfit.estimate_profitable_pool(
            pool_search_updated,
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
        {pool_event, pool_search, profit_amount, token_return, _return_amount, burrow_amount,
         token_return_amount_for_gas_fee, swap_price_event, swap_direction, _swap_amount}
      ) do
    %Pool{dex: %Dex{} = dex_event} =
      pool_event |> Repo.preload([:dex, token_pair: [:token0, :token1]])

    %Pool{dex: %Dex{} = dex_searched} =
      pool_search |> Repo.preload([:dex, token_pair: [:token0, :token1]])

    smart_contract_address =
      System.get_env("CONTRACT_ADDRESS")
      |> IO.inspect(label: "sx1 smart_contract_address")

    token_return
    |> LogWritter.ipt("sx1 token_return")

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
        token_profit: token_return,
        estimated_profit: (profit_amount / 10 ** profit_decimal_number) |> Float.to_string(),
        direction: swap_direction,
        tradable_amount: (burrow_amount / 10 ** profit_decimal_number) |> Float.to_string(),
        gas_fee:
          (token_return_amount_for_gas_fee / 10 ** profit_decimal_number) |> Float.to_string(),
        pool_event: pool_event,
        pool_search: pool_search
      }
      |> LogWritter.ipt("sx1 data test")

    ## TODO check direction for the swap order token0 to token1 or token1 to token0
    Sabv2Contract.execute_trade(
      token_path |> Enum.at(0) |> Map.get(:address),
      token_path |> Enum.at(1) |> Map.get(:address),
      dex_searched.router,
      dex_searched.abi,
      pool_search.fee |> String.to_integer(),
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
    |> maybe_save_response(data)
    |> IO.inspect(label: "sx1 execute_trade post Ethers.call()")

    # filter = Sabv2Contract.EventFilters.receive_flash_loan_event()
    # |> IO.inspect(label: "sx1 receive_flash_loan_event")

    Sabv2Contract.EventFilters.event_message()
    |> Ethers.get_logs()
    |> IO.inspect(label: "sx1 Event Log get_logs")
  end

  def sanitise_response(message) do
    case String.contains?(inspect(message), "0x") do
      true -> message
      false -> inspect(message)
    end
  end

  def maybe_save_response({:ok, msg}, data) do
    LogWritter.ipt("Transaction sent, return value: #{inspect(msg)}")

    # message =
    # case String.contains?(inspect(msg)V, "0x") do
    #   true -> msg
    #   false -> inspect(msg)
    # end

    updated_data =
      data
      |> Map.merge(%{smart_contract_response: sanitise_response(msg)})

    ProfitableTradeContext.insert(updated_data)
    |> LogWritter.ipt("sx1 ProfitableTradeContext.insert")

    {:ok, %{success: true}}
  end

  def maybe_save_response({:error, reason}, _data) do
    LogWritter.ipt("Transaction failed: #{inspect(reason)}")
    {:error, reason}
  end

  def maybe_save_response(message, _data) do
    LogWritter.ipt("Unexpected response: #{inspect(message)}")
    {:error, message}
  end

  def token_path_via_direction(%Token{} = token0, %Token{} = token1, direction)
      when direction in ["0_1", "O_I"],
      do: [token0, token1]

  def token_path_via_direction(%Token{} = token0, %Token{} = token1, direction)
      when direction in ["1_0", "I_O"],
      do: [token1, token0]
end
