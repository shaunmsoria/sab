defmodule TokenPairDexContext do
  import Ecto.{Changeset, Query}
  alias TokenPairDexSearch, as: TPDS
  alias DexSearch, as: DS


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

  def test() do
    token0 = TokenSearch.with_id(1) |> Repo.one()
    token1 = TokenSearch.with_id(2) |> Repo.one()
    dex1 = DexSearch.with_id(1) |> Repo.one()
    dex2 = DexSearch.with_id(2) |> Repo.one()

    # token_pair_dex = TokenPairDexSearch.with_id(5) |> Repo.one()
    # |> TokenPairDexContext.update(%{address: "address_test", price: "1000"})

    token_pair = TokenPairSearch.with_id(2) |> Repo.one()

    TokenPairDexContext.update_token_pair_dex(token_pair, dex2, %{address: "address_test2"})
    |> IO.inspect(label: "sx1 update_token_pair_dex")
  end
end
