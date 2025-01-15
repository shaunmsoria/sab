defmodule InvestigateEvent do
  import Compute
  alias ListDex, as: LD
  alias LogWritter, as: LW
  alias DexSearch, as: DS
  alias TokenContext, as: TC
  alias ProfitableTradeContext, as: PTC
  alias TokenPairDexSearch, as: TPDS
  alias TokenPairDexContext, as: TPDC

  alias PoolV2Context, as: PV2C

  @dexs Libraries.dexs()
  @balancer Libraries.balancer()

  def run(_state, event_data) when is_map(event_data) do
    with true <-
           not String.equivalent?(event_data.event.address, ""),
         token_pair_dex_address <- event_data.event.address,
         {:ok,
          %TokenPairDex{
            token_pair: %TokenPair{status: "active"} = token_pair,
            dex: %Dex{name: dex_name} = dex
          } = token_pair_dex_event} <-
           extract_token_pair_dex_details(token_pair_dex_address) do
      event_data.event.data |> IO.inspect(label: "sx1 event_data.event.data")

      maybe_investigate_event(event_data.event.data, event_data.event.name, token_pair_dex_event)
    else
      {:ok, %TokenPairDex{id: token_pair_id, token_pair: %TokenPair{status: "inactive"}}} ->
        IO.puts("sx1 TokenPair id: #{token_pair_id} Inactive")

      {:error, error_message} ->
        {:error, error_message} |> IO.inspect(label: "sx1")
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
        %TokenPairDex{
          token_pair: %TokenPair{status: "active"} = token_pair,
          dex: %Dex{name: dex_name} = dex,
          price: pool_price,
          reserve0: reserve0,
          reserve1: reserve1
        } = token_pair_dex_event
      ) do

    PV2C.check_profit(token_pair_dex_event, {amount0_in, amount0_out, amount1_in, amount1_out})
  end

  def extract_token_pair_dex_details(token_pair_dex_event_address) do
    with upcase_token_dex_event_address <- String.upcase(token_pair_dex_event_address),
         token_pair_dex_event <-
           TPDS.with_upcase_address(upcase_token_dex_event_address) |> Repo.one(),
         true <- not is_nil(token_pair_dex_event),
         token_pair_dex_event_preloaded <-
           token_pair_dex_event
           |> Repo.preload([[token_pair: [:dexs, :token0, :token1]], :dex]) do
      {:ok, token_pair_dex_event_preloaded}
    else
      _ -> {:error, "No TPD for #{token_pair_dex_event_address}"}
    end
  end
end
