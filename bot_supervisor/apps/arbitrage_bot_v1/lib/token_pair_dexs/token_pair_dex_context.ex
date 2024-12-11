defmodule TokenPairDexContext do
  import Ecto.{Changeset, Query}
  alias TokenPairDexSearch, as: TPDS
  alias TokenPairDexContext, as: TPDC
  alias DexSearch, as: DS
  alias LogWritter, as: LW

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

  def update_token_pair_dex_price(
        %TokenPairDex{
          id: token_pair_dex_id,
          address: token_pair_dex_address,
          price: token_pair_dex_price
        } = token_pair_dex,
        test \\ :TPD_searched
      ) do
    with {:ok, new_token_pair_dex_price} <-
           Compute.calculate_price(token_pair_dex_address),
         true <- token_pair_dex_price != "#{new_token_pair_dex_price}",
         {:ok, updated_token_pair_dex} <-
           TPDC.update(token_pair_dex, %{price: "#{new_token_pair_dex_price}"}) do
      LW.ipt(
        "TokenPairDex id: #{token_pair_dex_id} price updated to: #{new_token_pair_dex_price} with test: #{test}"
      )

      {:ok, updated_token_pair_dex}
    else
      _error ->
        if test == :return_test do
          {:error, "price same as db"}
        else
          {:ok, token_pair_dex}
        end
    end
  end

  def test() do
    token0 = TokenSearch.with_id(1) |> Repo.one()
    token1 = TokenSearch.with_id(2) |> Repo.one()
    dex1 = DexSearch.with_id(1) |> Repo.one()
    dex2 = DexSearch.with_id(2) |> Repo.one()

    token_pair =
      TokenPairSearch.with_id(3)
      |> Repo.one()
      |> Repo.preload([:dexs, :token0, :token1])
      |> IO.inspect(label: "token_pair")

    # token_pair_dex = TokenPairDexSearch.with_id(5) |> Repo.one()
    # |> TokenPairDexContext.update(%{address: "address_test", price: "1000"})

    # token_pair = TokenPairSearch.with_id(2) |> Repo.one()

    # TokenPairDexContext.update_token_pair_dex(token_pair, dex2, %{address: "address_test2"})
    # |> IO.inspect(label: "sx1 update_token_pair_dex")

    # token_pair_dex =
    #   TPDS.with_id(12)
    #   |> Repo.all()
    #   |> Repo.preload([[token_pair: [:dexs, :token0, :token1]], :dex])
    # |> IO.inspect(label: "token_pair_dex")

    extract_other_token_pair_dexs(token_pair, dex2)
    |> IO.inspect(label: "sx1 extract_other_token_pair_dexs")
  end
end
