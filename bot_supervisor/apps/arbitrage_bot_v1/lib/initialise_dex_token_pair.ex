defmodule InitialiseDexTokenPair do
  import Compute
  alias LogWritter, as: LW
  alias ListDex, as: LD
  alias DexSearch, as: DS
  alias DexContext, as: DC
  alias TokenSearch, as: TS
  alias TokenContext, as: TC
  alias TokenPairSearch, as: TPS
  alias TokenPairContext, as: TPC
  alias TokenPairDexContext, as: TPDC
  alias LogWritter, as: LW

  ##TODO
  # remove comment in get_pairs_for_dex to allow the system to update for all token_pairs

  def run() do
    with list_dexs <- DS.query() |> Repo.all(),
         {:ok, list_dex_token_pairs_length_updated} <- get_all_token_pairs_length(list_dexs) do
          {:ok, :database_ready}
    end
  end

  def get_all_token_pairs_length(list_dexs) do
    list_dexs
    |> Enum.map(fn dex ->
      maybe_update_dex_all_pairs(dex)
    end)
  end

  def maybe_update_dex_all_pairs(%Dex{all_pairs_length: nil, factory: factory} = dex) do
    with {:ok, dex_all_pairs_length} <- get_all_pairs_length(factory),
         {:ok, :all_pairs_retrieved} <- get_pairs_for_dex(dex, dex_all_pairs_length) do
      {:ok, dex}
    end
  end

  def maybe_update_dex_all_pairs(
        %Dex{
          name: dex_name,
          all_pairs_length: current_all_pairs_length,
          factory: factory
        } = dex
      ) do
    with {:ok, dex_all_pairs_length} <- get_all_pairs_length(factory) do
      if dex_all_pairs_length == current_all_pairs_length do
        IO.puts("dex: #{dex_name} is up to date")
      else
        get_pairs_for_dex(dex, dex_all_pairs_length, current_all_pairs_length + 1)
        IO.puts("dex: #{dex_name} have been updated")
      end

      {:ok, dex}
    end
  end

  def get_pairs_for_dex(%Dex{} = dex, dex_all_pairs_length, start_all_pairs_length \\ 0) do
    # start_all_pairs_length..dex_all_pairs_length
    start_all_pairs_length..15
    |> Enum.map(fn n_pair ->
      n_pair |> IO.inspect(label: "n_pair")

      get_or_create_pair_for_dex(dex, n_pair)
    end)

    {:ok, :all_pairs_retrieved}
  end

  def get_or_create_pair_for_dex(%Dex{name: dex_name, factory: factory} = dex, n_pair) do
    with {:ok, pair_address} <- get_all_pairs(factory, n_pair),
         {:ok, token0_address} <- pair_address |> contract(:token0),
         {:ok, token1_address} <- pair_address |> contract(:token1),
         {:ok, token0} <- maybe_add_token(token0_address),
         {:ok, token1} <- maybe_add_token(token1_address),
         {:ok, token_pair} <- maybe_add_token_pair(token0, token1, dex),
         {:ok, token_pair_dex} <-
           TPDC.update_with_token_pair_and_dex(token_pair, dex, %{address: pair_address}),
         {:ok, updated_dex} <- dex |> DC.update(%{all_pairs_length: n_pair}) do
      {:ok, token_pair_dex}
    else
      error ->
        :timer.sleep(30000)

        LW.ipt(
          "dex: #{dex_name} for n_pair: #{n_pair} not retrieved because of: #{inspect(error)}"
        )

        get_or_create_pair_for_dex(%Dex{factory: factory} = dex, n_pair)
    end
  end

  def maybe_add_token_pair(
        %Token{id: token0_id},
        %Token{id: token1_id},
        %Dex{} = dex
      ) do
    case TPS.with_token0_id(token0_id)
         |> TPS.with_token1_id(token1_id)
         |> Repo.one() do
      nil ->
        with {:ok, token_pair} <-
               %{
                 token0_id: token0_id,
                 token1_id: token1_id,
                 dexs: [dex],
                 status: "inactive"
               }
               |> TPC.insert() do
          {:ok, token_pair}
        end

      %TokenPair{} = token_pair ->
        with {:ok, updated_token_pair} <-
               token_pair
               |> TPC.update(%{
                 dexs: [dex],
                 status: "active"
               }) do
          {:ok, updated_token_pair}
        end
    end
  end

  def maybe_add_token(token_address) do
    case TS.with_address(token_address) |> Repo.one() do
      nil ->
        with {:ok, symbol} <- token_address |> contract(:symbol),
             {:ok, name} <- token_address |> contract(:name),
             {:ok, decimals} <- token_address |> contract(:decimals),
             {:ok, token} <-
               %{
                 symbol: symbol,
                 name: name,
                 address: token_address,
                 decimals: decimals
               }
               |> TC.insert() do
          {:ok, token}
        end

      %Token{} = token ->
        {:ok, token}
    end
  end
end
