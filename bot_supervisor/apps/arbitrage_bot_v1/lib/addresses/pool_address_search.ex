defmodule PoolAddressSearch do
  import Ecto.Query

  ## add Repo.all() or Repo.one() get the results
  def query() do
    from(PoolAddress)
    # |> Repo.all()
  end

  def with_id(query \\ query(), id) do
    from(t in query, where: t.id == ^id)
  end

  def with_address(query \\ query(), address) do
    from(t in query, where: t.address == ^address)
  end

  def with_upcase_address(query \\ query(), upcase_address) do
    from(t in query, where: t.upcase_address == ^upcase_address)
  end

  def with_status(query \\ query(), status) do
    from(t in query, where: t.status == ^status)
  end

  def with_pool_id(query \\ query(), pool_id) do
    from(t in query, where: t.pool_id == ^pool_id)
  end
end
