defmodule TokenSearch do
  import Ecto.Query

  ## add Repo.all() or Repo.one() get the results
  def query() do
    from(Token)
    # |> Repo.all()
  end

  def with_id(query \\ query(), id) do
    from(t in query, where: t.id == ^id)
  end

  def with_symbol(query \\ query(), symbol) do
    from(t in query, where: t.symbol == ^symbol)
  end

  def with_name(query \\ query(), name) do
    from(t in query, where: t.name == ^name)
  end

  def with_address(query \\ query(), address) do
    from(t in query, where: t.address == ^address)
  end

  def with_decimals(query \\ query(), decimals) do
    from(t in query, where: t.decimals == ^decimals)
  end
end
