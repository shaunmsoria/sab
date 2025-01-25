defmodule TokenPairDexContext do
  import Compute
  import Ecto.{Changeset, Query}
  alias TokenPairDexSearch, as: TPDS
  alias TokenPairDexContext, as: TPDC
  alias DexSearch, as: DS
  alias LogWritter, as: LW
  alias TokenPairSearch, as: TPS
  alias TokenPairContext, as: TPC
  alias TokenSearch, as: TS

  def update(%TokenPairDex{} = token_pair_dex, params) do
    token_pair_dex
    |> TokenPairDex.update_changeset(params)
    |> Repo.update()
  end

  def update_with_token_pair_and_dex(%TokenPair{id: token_pair_id}, %Dex{id: dex_id}, params) do
    with %TokenPairDex{} = token_pair_dex <-
           TPDS.with_token_pair_id(token_pair_id) |> TPDS.with_dex_id(dex_id) |> Repo.one() do
      token_pair_dex
      |> TokenPairDexContext.update(params)
    end
  end

  def extract_other_token_pair_dexs(
        %TokenPair{id: token_pair_id, dexs: dexs} = token_pair,
        %Dex{name: dex_name} = dex
      ) do
    with filtered_dexs <-
           dexs
           |> Enum.filter(fn dex_searched ->
             dex_searched
             |> Map.get(:name) != dex_name
           end),
         list_token_pair_dexs <-
           filtered_dexs
           |> Enum.map(fn %Dex{id: dex_id} ->
             TPDS.with_dex_id(dex_id)
             |> TPDS.with_token_pair_id(token_pair_id)
             |> Repo.one()
             |> Repo.preload([:dex, :token_pair])
           end) do
      case list_token_pair_dexs do
        [] ->
          {:error, "no_profitable_trades"}

        list_token_pair_dexs ->
          {:ok, list_token_pair_dexs}
      end
    end
  end

  def update_token_pair_dex_price(%TokenPairDex{} = token_pair_dex),
    do: update_token_pair_dex_price(token_pair_dex, :TPD_searched)

  def update_token_pair_dex_price(
        %TokenPairDex{
          id: token_pair_dex_id,
          address: token_pair_dex_address,
          price: nil,
          dex: %Dex{name: dex_name}
        } = token_pair_dex,
        test
      ) do
    with {:ok, new_token_pair_dex_price, reserve0, reserve1} <-
           Compute.calculate_price(token_pair_dex_address),
         {:ok, updated_token_pair_dex} <-
           TPDC.update(token_pair_dex, %{
             price: "#{new_token_pair_dex_price}",
             reserve0: "#{reserve0}",
             reserve1: "#{reserve1}"
           }) do
      LW.ipt(
        "#{test} id: #{token_pair_dex_id} on Dex: #{dex_name} price updated to: #{new_token_pair_dex_price}"
      )

      {:ok, updated_token_pair_dex}
    else
      error ->
        {:error, error}
    end
  end

  def update_token_pair_dex_price(
        %TokenPairDex{
          id: token_pair_dex_id,
          address: token_pair_dex_address,
          price: token_pair_dex_price,
          dex: %Dex{name: dex_name}
        } = token_pair_dex,
        test
      ) do
    with {:ok, new_token_pair_dex_price, reserve0, reserve1} <-
           Compute.calculate_price(token_pair_dex_address),
         true <-
           token_pair_dex_price != "#{new_token_pair_dex_price}",
         {:ok, updated_token_pair_dex} <-
           TPDC.update(token_pair_dex, %{
             price: "#{new_token_pair_dex_price}",
             reserve0: "#{reserve0}",
             reserve1: "#{reserve1}"
           }) do
      LW.ipt(
        "#{test} id: #{token_pair_dex_id} on Dex: #{dex_name}  price updated to: #{new_token_pair_dex_price}"
      )

      {:ok, updated_token_pair_dex}
    else
      _error ->
        if test == :TPD_event do
          {:error, "price same as db"}
        else
          LW.ipt(
            "#{test} id: #{token_pair_dex_id} on Dex: #{dex_name}  price not updated: #{token_pair_dex_price}"
          )

          {:ok, token_pair_dex}
        end
    end
  end

  def maybe_add_token_pair_dex(
        %Token{id: token0_id} = token0,
        %Token{id: token1_id} = token1,
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
                 status: "inactive",
                 decimals_adjsuter_0_1: calculate_decimals_adjuster_0_1(token0, token1)
               }
               |> TPC.insert() do
          {:ok, token_pair}
        end

      %TokenPair{} = token_pair ->
        with {:ok, updated_token_pair} <-
               token_pair
               |> TPC.update(%{
                 dexs: [dex],
                 status: "active",
                 decimals_adjuster_0_1: calculate_decimals_adjuster_0_1(token_pair)
               }) do
          {:ok, updated_token_pair}
        end
    end
  end
end
