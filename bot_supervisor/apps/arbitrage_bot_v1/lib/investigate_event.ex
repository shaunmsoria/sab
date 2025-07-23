defmodule InvestigateEvent do
  @moduledoc """
    try to indentify necessary information about events to be acted upon
  """

  import Compute
  alias ListDex, as: LD
  alias LogWritter, as: LW
  alias DexSearch, as: DS
  alias TokenContext, as: TC
  alias ProfitableTradeContext, as: PTC
  alias PoolSearch, as: PS
  alias PoolContext, as: PC
  alias PoolAddressSearch, as: PAS
  alias PoolAddressContext, as: PAC

  alias PoolV2Context, as: PV2C
  alias PoolV3Context, as: PV3C

  alias ProcessTrade, as: PT

  @dexs Libraries.dexs()
  @balancer Libraries.balancer()

  def run(_state, event_data) when is_map(event_data) do
    event_data |> LW.ipt("sx1 event_data")

    with true <- event_data.event.address !== "",
         {:ok,
          %Pool{
            token_pair: %TokenPair{status: "active"} = token_pair,
            dex: %Dex{name: dex_name} = dex
          } = pool_event} <-
           extract_pool_details(event_data.event.address, event_data.event.data) do
      # event_data.event.data |> IO.inspect(label: "sx1 event_data.event.data")

      maybe_investigate_event(event_data.event.data, event_data.event.name, pool_event)
    else
      {:ok, %Pool{id: token_pair_id, token_pair: %TokenPair{status: "inactive"}}} ->
        IO.puts("sx1 TokenPair id: #{token_pair_id} Inactive")

      error_message ->
        {:error, inspect(error_message)} |> IO.inspect(label: "sx1")
    end
  end

  def maybe_investigate_event(
        %{
          "amount0In" => amount0_in,
          "amount0Out" => amount0_out,
          "amount1In" => amount1_in,
          "amount1Out" => amount1_out,
          "sender" => _sender_address,
          "to" => _to_address
        },
        "Swap",
        %Pool{
          token_pair: %TokenPair{status: "active"} = token_pair,
          dex: %Dex{name: dex_name} = dex,
          price: pool_price,
          reserve0: reserve0,
          reserve1: reserve1
        } = pool_event
      ) do
    LogWritter.ipt("sx1 pool_event id: #{pool_event.id} maybe_investigate_event pool v2")

    # CheckProfit.run(pool_event, {
    #   maybe_sanitise_amounts(amount0_in),
    #   maybe_sanitise_amounts(amount0_out),
    #   maybe_sanitise_amounts(amount1_in),
    #   maybe_sanitise_amounts(amount1_out)
    # })
    # |> case do
    #   [] ->
    #     {:ok, "No profitable trade found"}

    #   {:error, msg} ->
    #     msg |> LogWritter.ipt("sx1 CheckProfit.run error")

    #   profitable_trades ->
    #     profitable_trades
    #     |> PT.run()
    # end
  end

  def maybe_investigate_event(
        %{
          "amount0" => amount0_delta,
          "amount1" => amount1_delta,
          "liquidity" => liquidity,
          "recipient" => _recipient,
          "sender" => _sender,
          "sqrtPriceX96" => sqrtPriceX96,
          "tick" => tick
        },
        "Swap",
        %Pool{
          token_pair: %TokenPair{status: "active"} = token_pair,
          dex: %Dex{name: dex_name} = dex,
          price: pool_price,
          reserve0: reserve0,
          reserve1: reserve1
        } = pool_event
      ) do
    LogWritter.ipt("sx1 pool_event id: #{pool_event.id} maybe_investigate_event pool v3")

    CheckProfit.run(pool_event, {
      maybe_sanitise_amounts(amount0_delta),
      maybe_sanitise_amounts(amount1_delta),
      maybe_sanitise_amounts(liquidity),
      maybe_sanitise_amounts(sqrtPriceX96),
      maybe_sanitise_amounts(tick)
    })
    |> case do
      [] ->
        {:ok, "No profitable trade found"}

      profitable_trades ->
        profitable_trades
        |> PT.run()
    end
  end

  def maybe_investigate_event(
        swap_data,
        "Swap",
        pool
      ) do
    inspect(swap_data)
    inspect(pool)
  end

  def extract_pool_details(address, event_params) do
    with upcase_address <- String.upcase(address),
         pool_address <-
           PAS.with_upcase_address(upcase_address)
           |> PAS.with_status("active")
           |> Repo.one(),
         true <- not is_nil(pool_address),
         pool_event <- pool_address |> Repo.preload(:pool) |> Map.get(:pool),
         pool_event_preloaded <-
           pool_event
           |> Repo.preload([[token_pair: [:token0, :token1]], :dex]) do
      {:ok, pool_event_preloaded}
    else
      msg ->
        msg |> IO.inspect(label: "mx1 extract_pool_details else")

        maybe_create_pool(address, event_params)
    end
  end

  def maybe_sanitise_amounts(""), do: 0

  def maybe_sanitise_amounts(amount) when is_binary(amount),
    do: amount |> String.to_integer()

  def maybe_sanitise_amounts(amount) when is_integer(amount),
    do: amount

  def maybe_create_pool(event_address, event_params) do
    with {:ok, pool_address} <- PAC.maybe_add_pool_address(event_address) do
      case PC.maybe_add_pool_from_pool_address(pool_address, event_params) do
        {:ok, pool} ->
          {:ok, pool |> Repo.preload([[token_pair: [:token0, :token1]], :dex])}

        {:error, error_message} ->
          {:error, "No Pool for #{event_address}, reason: #{inspect(error_message)}"}

        error_message ->
          {:error, "No Pool for #{event_address}, reason: #{inspect(error_message)}"}
      end
    else
      error_message ->
        {:error, "No Pool for #{event_address}, reason: #{inspect(error_message)}"}
    end
  end
end
