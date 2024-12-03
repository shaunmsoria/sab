defmodule TokenPairContext do
  import Ecto.{Changeset, Query, Repo}

  def insert(params) do
    %TokenPair{}
    |> TokenPair.changeset(params)
    |> Repo.insert()
  end

  def update(%TokenPair{} = token_pair, params) do
    token_pair
    |> Repo.preload(:dexs)
    |> TokenPair.update_changeset(params)
    |> Repo.update()
  end

  def test() do
    token0 = TokenSearch.with_id(5) |> Repo.one()
    token1 = TokenSearch.with_id(6) |> Repo.one()
    dex1 = DexSearch.with_id(1) |> Repo.one()
    dex2 = DexSearch.with_id(2) |> Repo.one()

    token_pair =
      TokenPairSearch.with_id(9)
      |> Repo.one()
      |> Repo.preload([:token0, :token1, :dexs])
      # |> TokenPairContext.update(%{dexs: [dex2], status: "test"})

    # TokenPairContext.insert(%{token0_id: 5, token1_id: 6, dexs: [dex], status: "test"})
  end
end
