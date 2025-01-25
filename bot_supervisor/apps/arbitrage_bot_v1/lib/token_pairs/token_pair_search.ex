defmodule TokenPairSearch do
  import Ecto.Query

  ## add Repo.all() or Repo.one() get the results
  def query() do
    from(TokenPair)
    # |> Repo.all()
  end

  def with_id(query \\ query(), id) do
    from(t in query, where: t.id == ^id)
  end

  def with_token0_id(query \\ query(), token0_id) do
    from(t in query, where: t.token0_id == ^token0_id)
  end
  def with_token1_id(query \\ query(), token1_id) do
    from(t in query, where: t.token1_id == ^token1_id)
  end

  def with_status(query \\ query(), status) do
    from(t in query, where: t.status == ^status)
  end

  def with_decimals_adjuster_0_1(query \\ query(), decimals_adjuster_0_1) do
    from(t in query, where: t.decimals_adjuster_0_1 == ^decimals_adjuster_0_1)
  end

end
