defmodule DexSearch do
  import Ecto.Query

  ## add Repo.all() or Repo.one() get the results
  def query() do
    from(Dex)
    # |> Repo.all()
  end

  def with_id(query \\ query(), id) do
    from(t in query, where: t.id == ^id)
  end

  def with_router(query \\ query(), router) do
    from(t in query, where: t.router == ^router)
  end

  def with_name(query \\ query(), name) do
    from(t in query, where: t.name == ^name)
  end

  def with_factory(query \\ query(), factory) do
    from(t in query, where: t.factory == ^factory)
  end

  def with_version(query \\ query(), version) do
    from(t in query, where: t.version == ^version)
  end

  def with_all_pair_length(query \\ query(), all_pair_length) do
    from(t in query, where: t.all_pair_length == ^all_pair_length)
  end
end
