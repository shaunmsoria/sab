defmodule ProfitableTradeSearch do
  import Ecto.Query

  ## add Repo.all() or Repo.one() get the results
  def query() do
    from(ProfitableTrade)
    # |> Repo.all()
  end

  def with_id(query \\ query(), id) do
    from(p in query, where: p.id == ^id)
  end

  def with_token_pair_id(query \\ query(), token_pair_id) do
    from(p in query, where: p.token_pair_id == ^token_pair_id)
  end
  def with_dex_id(query \\ query(), dex_id) do
    from(p in query, where: p.dex_id == ^dex_id)
  end

  def with_address(query \\ query(), address) do
    from(p in query, where: p.address == ^address)
  end
  def with_price(query \\ query(), price) do
    from(p in query, where: p.price == ^price)
  end

end
