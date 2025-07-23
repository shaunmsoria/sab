defmodule Repo.Migrations.AddPoolSearchIdToProfitableTable do
  use Ecto.Migration

  def change do
    alter table(:profitable_trades) do
      add :pool_search_id, references(:pools)
    end
  end
end
