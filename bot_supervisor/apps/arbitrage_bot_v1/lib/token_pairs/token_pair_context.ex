defmodule TokenPairContext do
  import Ecto.{Changeset, Query}

  def insert(params) do
    %TokenPair{}
    |> TokenPair.changeset(params)
    |> Repo.insert()
  end

  def update(%TokenPair{} = token_pair, params) do
    token_pair
    |> TokenPair.changeset(params)
    |> Repo.update()
  end


  def test() do
    token0 = TokenSearch.with_id(1) |> Repo.one()
    token1 = TokenSearch.with_id(2) |> Repo.one()
    dex = DexSearch.with_id(1) |> Repo.one()

    # token_pair = TokenPairSearch.with_id(1) |> Repo.one() |> Repo.preload([:token0, :token1, :dexs])
    # |> TokenPairContext.update(%{token0: token0, token1: token1, dexs: [dex], status: "test"})

    TokenPairContext.insert(%{token0: token0, token1: token1, dexs: [dex], status: "test"})
  end

end
