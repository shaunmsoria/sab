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


  def test() do
    token_pair = TokenPairSearch.with_id(2) |> Repo.one()
    dex_emitted = DexSearch.with_id(1) |> Repo.one()
    dex_searched = DexSearch.with_id(2) |> Repo.one()
    token_profit = TokenSearch.with_id(1) |> Repo.one()

    # token_pair_dex = TokenPairDexSearch.with_id(1) |> Repo.one() |> Repo.preload([:token_pair, :dex])
    # |> TokenPairDexContext.update(%{address: "address_test", price: "1000"})

    profitable_trade =
      ProfitableTradeSearch.with_direction(":I_O")
      |> Repo.all()
      # |> Repo.preload([:token_pair, :dex_emitted, :dex_searched, :token_profit])
      |> IO.inspect(label: "sx1 profitable_trade")


    # insert(%{
    #   token_pair: token_pair,
    #   dex_emitted: dex_emitted,
    #   dex_searched: dex_searched,
    #   token_profit: token_profit,
    #   estimated_profit: "0.233455",
    #   direction: ":I_O",
    #   tradable_amount: "36873973",
    #   gas_fee: "7979",
    #   smart_contract_response: "sc respnse"})


    # ProfitableTradeContext.update(profitable_trade, %{
    #   token_pair: token_pair,
    #   dex_emitted: dex_emitted,
    #   dex_searched: dex_searched,
    #   token_profit: token_profit,
    #   estimated_profit: "0.433455",
    #   direction: ":I_O",
    #   tradable_amount: "56873973",
    #   gas_fee: "10000",
    #   smart_contract_response: "sc respnse 2"})

  end

end
