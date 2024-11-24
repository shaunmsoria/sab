defmodule ProfitableTradeContext do
  import Ecto.{Changeset, Query}

  def insert(params) do
    %ProfitableTrade{}
    |> ProfitableTrade.changeset(params)
    |> Repo.insert()
  end

  def update(%ProfitableTrade{} = profitable_trade, params) do
    profitable_trade
    |> ProfitableTrade.changeset(params)
    |> Repo.update()
  end


  ##TODO do the test below
  def test() do
    token_pair = TokenPairSearch.with_id(1) |> Repo.one()
    dex_emitted = DexSearch.with_id(1) |> Repo.one()
    dex_searched = DexSearch.with_id(2) |> Repo.one()
    token_profit = TokenSearch.with_id(1) |> Repo.one()

    # token_pair_dex = TokenPairDexSearch.with_id(1) |> Repo.one() |> Repo.preload([:token_pair, :dex])
    # |> TokenPairDexContext.update(%{address: "address_test", price: "1000"})

    insert(%{
      token_pair: token_pair,
      dex_emitted: dex_emitted,
      dex_searched: dex_searched,
      token_profit: token_profit,
      estimated_profit: "0.233455",
      direction: ":I_O",
      tradable_amount: "36873973",
      gas_fee: "7979",
      smart_contract_response: "sc respnse"})

  end

end
