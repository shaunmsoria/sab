defmodule ProcessTrade do
  import Compute

  alias Sabv2Contract.EventFilters

  @dexs Libraries.dexs()

  def run([]),
    do: LogWritter.ipt("sx1 no profitable trades to execute")

  def run({:error, msg}),
    do: LogWritter.ipt("sx1 error in profitable trades: #{inspect(msg)}")

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

    uuid = Ecto.UUID.generate()

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
        pool_search: pool_search,
        uuid: uuid
      }
      |> LogWritter.ipt("sx1 data test")

    Sabv2Contract.execute_trade(
      [
        token_path |> Enum.at(0) |> Map.get(:address),
        token_path |> Enum.at(1) |> Map.get(:address)
      ],
      [dex_searched.router, dex_event.router],
      dex_searched.abi,
      dex_event.abi,
      [String.to_integer(pool_search.fee), String.to_integer(pool_event.fee)],
      burrow_amount |> trunc(),
      uuid
    )
    |> IO.inspect(label: "sx1 execute_trade pre Ethers.send_transaction()")
    |> Ethers.send(
      signer: Ethers.Signer.Local,
      signer_opts: [private_key: System.get_env("PRIVATE_KEY")],
      value: 0,
      to: smart_contract_address,
      from: System.get_env("ACCOUNT_NUMBER")
    )
    |> maybe_save_response(data)
    |> IO.inspect(label: "sx1 execute_trade post Ethers.call()")

    ## ? test for wallet balance to be use in prod
    # {:ok, token0_balance} =
    #   Ethers.Contracts.ERC20.balance_of(System.get_env("ACCOUNT_NUMBER"))
    #   |> Ethers.call(to: token_path |> Enum.at(0) |> Map.get(:address))

    # {:ok, token1_balance} =
    #   Ethers.Contracts.ERC20.balance_of(System.get_env("ACCOUNT_NUMBER"))
    #   |> Ethers.call(to: token_path |> Enum.at(1) |> Map.get(:address))

    #   %{token0_address: token_path |> Enum.at(0) |> Map.get(:address),
    #     token0_balance: token0_balance,
    #     token1_address: token_path |> Enum.at(1) |> Map.get(:address),
    #     token1_balance: token1_balance
    #   }
    #   |> IO.inspect(label: "sx1 balance")
  end

  def sanitise_response(message) do
    case String.contains?(inspect(message), "0x") do
      true -> message
      false -> inspect(message)
    end
  end

  def get_event_data(uuid) do
    {:ok, logs} =
      Sabv2Contract.EventFilters.swap_receipt()
      |> Ethers.get_logs()
      |> LogWritter.ipt("sx1 get_logs")

    logs
    |> Enum.filter(fn log -> List.first(log.data) == uuid end)
    |> List.first()
    |> case do
      nil ->
        %{}

      event_data ->
        map_pre_format =
          event_data
          |> Map.from_struct()
          |> Map.take([:data, :block_number])

        %{
          block_number: "#{map_pre_format.block_number}",
          uuid: "#{Enum.at(map_pre_format.data, 0)}",
          flash_amount: "#{Enum.at(map_pre_format.data, 1)}",
          loan_fee: "#{Enum.at(map_pre_format.data, 2)}",
          token0_amount: "#{Enum.at(map_pre_format.data, 3)}",
          profit: "#{Enum.at(map_pre_format.data, 4)}",
          remaining: "#{Enum.at(map_pre_format.data, 5)}"
        }
    end
  end

  def maybe_save_response({:ok, msg}, data) do
    LogWritter.ipt("Transaction sent, return value: #{inspect(msg)}")

    updated_data =
      data
      |> Map.merge(%{
        smart_contract_response: sanitise_response(msg),
        event_data: get_event_data(data.uuid)
      })

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
