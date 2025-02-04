defmodule TokenPairContext do
  import Compute
  import Ecto.{Changeset, Query, Repo}
  alias TokenPairContext, as: TPC

  def insert(params) do
    %TokenPair{}
    |> TokenPair.changeset(params)
    |> Repo.insert()
  end

  def update(%TokenPair{} = token_pair, params) do
    token_pair
    |> TokenPair.update_changeset(params)
    |> Repo.update()
  end

  def update_decimals_adjuster_0_1(
        %TokenPair{
          decimals_adjuster_0_1: nil
        } = token_pair
      ),
      do:
        token_pair
        |> TPC.update(%{decimals_adjuster_0_1: calculate_decimals_adjuster_0_1(token_pair)})

  def update_decimals_adjuster_0_1(
        %TokenPair{
          decimals_adjuster_0_1: _decimals_adjuster_0_1
        } = token_pair
      ),
      do: token_pair

  def test() do
    token0 = TokenSearch.with_id(5) |> Repo.one()
    token1 = TokenSearch.with_id(6) |> Repo.one()
    dex1 = DexSearch.with_id(1) |> Repo.one()
    dex2 = DexSearch.with_id(2) |> Repo.one()

    token_pair =
      TokenPairSearch.with_id(9)
      |> Repo.one()
      |> Repo.preload([:token0, :token1])

    # |> TokenPairContext.update(%{dexs: [dex2], status: "test"})

    # TokenPairContext.insert(%{token0_id: 5, token1_id: 6, dexs: [dex], status: "test"})
  end
end
