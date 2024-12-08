defmodule TokenPairDexSearch do
  import Ecto.Query

  ## add Repo.all() or Repo.one() get the results
  def query() do
    from(TokenPairDex)
    # |> Repo.all()
  end

  def with_id(query \\ query(), id) do
    from(t in query, where: t.id == ^id)
  end

  def with_token_pair_id(query \\ query(), token_pair_id) do
    from(t in query, where: t.token_pair_id == ^token_pair_id)
  end
  def with_dex_id(query \\ query(), dex_id) do
    from(t in query, where: t.dex_id == ^dex_id)
  end

  def with_address(query \\ query(), address) do
    from(t in query, where: t.address == ^address)
  end
  def with_price(query \\ query(), price) do
    from(t in query, where: t.price == ^price)
  end
  def with_upcase_address(query \\ query(), upcase_address) do
    from(t in query, where: t.upcase_address == ^upcase_address)
  end

end
