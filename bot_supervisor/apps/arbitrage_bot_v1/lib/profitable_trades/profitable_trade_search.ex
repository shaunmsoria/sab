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
  def with_dex_emitted_id(query \\ query(), dex_emitted_id) do
    from(p in query, where: p.dex_eimtted_id == ^dex_emitted_id)
  end
  def with_dex_searched_id(query \\ query(), dex_searched_id) do
    from(p in query, where: p.dex_searched_id == ^dex_searched_id)
  end
  def with_token_profit_id(query \\ query(), token_profit_id) do
    from(p in query, where: p.token_profit_id == ^token_profit_id)
  end

  def with_estimated_profit(query \\ query(), estimated_profit) do
    from(p in query, where: p.estimated_profit == ^estimated_profit)
  end
  def with_direction(query \\ query(), direction) do
    from(p in query, where: p.direction == ^direction)
  end
  def with_tradable_amount(query \\ query(), tradable_amount) do
    from(p in query, where: p.tradable_amount == ^tradable_amount)
  end
  def with_gas_fee(query \\ query(), gas_fee) do
    from(p in query, where: p.gas_fee == ^gas_fee)
  end
  def with_smart_contract_response(query \\ query(), smart_contract_response) do
    from(p in query, where: p.smart_contract_response == ^smart_contract_response)
  end

end
