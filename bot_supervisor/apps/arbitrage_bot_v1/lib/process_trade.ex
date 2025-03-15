defmodule ProcessTrade do
  import Compute
  alias ProfitableTradeContext, as: PTC
  alias LogWritter, as: LW
  alias PoolContext, as: PC
  alias PoolV3CheckProfit, as: PV3CP

  @dexs Libraries.dexs()

  def run([]),
    do: IO.puts("sx1 no profitable trades to execute")

  ## TODO check if gas in wallet is enough to pay for the gas fee
  def run(potential_profitable_trades) when is_list(potential_profitable_trades) do
    potential_profitable_trades
    |> Enum.reduce_while(false, fn trade, acc ->
      case maybe_execute_trade(trade) do
        false ->
          {:cont, acc}

        true ->
          {:halt, true}
      end
    end)
  end

  def maybe_execute_trade(
        {pool_event, pool_searched, _profit_amount, _token_return_symbol, _return_amount,
         _burrow_amount, _token_return_amount_for_gas_fee, swap_price_event,
         swap_direction} = params
      ) do
    current_pool_price = pool_searched.price

    with {:ok, pool_searched_updated} <- PC.update_pool_price(pool_searched) do
      case current_pool_price == pool_searched_updated.price do
        true ->
          execute_trade(params)

        false ->
          PV3CP.estimate_profitable_pool(
            pool_event,
            pool_searched_updated,
            swap_price_event,
            swap_direction
          )
          |> case do
            [] -> false
            profitable_trade -> execute_trade(profitable_trade)
          end
      end
    end
  end

  def execute_trade(
        {pool_event, pool_searched, _profit_amount, _token_return_symbol, _return_amount,
         burrow_amount, _token_return_amount_for_gas_fee, swap_price_event, swap_direction}
      ) do
    %Pool{dex: %Dex{} = dex_event} =
      pool_event |> Repo.preload([:dex, token_pair: [:token0, :token1]])

    %Pool{dex: %Dex{} = dex_searched} =
      pool_searched |> Repo.preload([:dex, token_pair: [:token0, :token1]])

    smart_contract_address =
      System.get_env("CONTRACT_ADDRESS")

    ## TODO implement trade execution with new smart contract
    Sabv2Contract.execute_trade(
      pool_event.token_pair.token0.address,
      pool_event.token_pair.token1.address,
      pool_event.dex.router,
      pool_event.dex.abi,
      pool_event.fee,
      pool_searched.dex.router,
      pool_searched.dex.abi,
      pool_searched.fee,
      burrow_amount
    )
    |> IO.inspect(label: "sx1 execute_trade pre Ethers.call()")
    |> Ethers.call(to: smart_contract_address)
    |> IO.inspect(label: "sx1 execute_trade post Ethers.call()")
  end
end
