defmodule TokenPairDexContext do
  import Ecto.{Changeset, Query}


  ##TODO to be tested
  def update(%TokenPairDex{} = token_pair_dex, params) do
    token_pair_dex
    |> TokenPairDex.update_changeset(params)
    |> Repo.update()
  end


  def test() do
    token0 = TokenSearch.with_id(1) |> Repo.one()
    token1 = TokenSearch.with_id(2) |> Repo.one()
    dex = DexSearch.with_id(1) |> Repo.one()

    token_pair_dex = TokenPairDexSearch.with_id(1) |> Repo.one() |> Repo.preload([:token_pair, :dex])
    |> TokenPairDexContext.update(%{address: "address_test", price: "1000"})

  end

end
