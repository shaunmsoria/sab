defmodule ProfitableTrade do
  use Ecto.Schema
  import Ecto.{Changeset, Query}

  schema "profitable_trades" do
    belongs_to(:token_pair, TokenPair)
    belongs_to(:dex_emitted, Dex)
    belongs_to(:dex_searched, Dex)
    belongs_to(:token_profit, Token)
    belongs_to(:pool_event, Pool)
    belongs_to(:pool_search, Pool)
    field(:estimated_profit, :string)
    field(:direction, :string)
    field(:tradable_amount, :string)
    field(:gas_fee, :string)
    field(:smart_contract_response, :string)
    field(:event_data, :map)

    timestamps()
  end

  @required [:estimated_profit, :direction, :tradable_amount, :gas_fee]
  @optional [:smart_contract_response, :event_data]

  def changeset(
        %ProfitableTrade{} = profitable_trade,
        %{
          token_pair: token_pair,
          dex_emitted: dex_emitted,
          dex_searched: dex_searched,
          token_profit: token_profit,
          pool_event: pool_event,
          pool_search: pool_search
        } = params
      ) do
    profitable_trade
    |> cast(params, @required ++ @optional)
    |> put_assoc(:token_pair, token_pair)
    |> put_assoc(:dex_emitted, dex_emitted)
    |> put_assoc(:dex_searched, dex_searched)
    |> put_assoc(:token_profit, token_profit)
    |> put_assoc(:pool_event, pool_event)
    |> put_assoc(:pool_search, pool_search)
    |> validate_required(@required)
  end

  def update_changeset(%ProfitableTrade{} = profitable_trade, params) do
    profitable_trade
    |> cast(params, @required ++ @optional)
    |> validate_required(@required)
  end
end
