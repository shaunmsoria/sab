defmodule Repo.Migrations.CreateProfitableTradeTable do
  use Ecto.Migration

  def change do
    create table(:profitable_trades) do
      add :token_pair_id, references(:token_pairs)
      add :dex_emitted_id, references(:dexs)
      add :dex_searched_id, references(:dexs)
      add :token_profit_id, references(:tokens)
      add :estimated_profit, :string
      add :direction, :string
      add :tradable_amount, :string
      add :gas_fee, :string
      add :smart_contract_response, :string

      timestamps()
    end

  end
end
