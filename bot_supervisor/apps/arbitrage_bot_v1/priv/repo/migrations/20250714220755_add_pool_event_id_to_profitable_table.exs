defmodule Repo.Migrations.AddPoolEventIdToProfitableTable do
  use Ecto.Migration

  def change do
    alter table(:profitable_trades) do
      add :pool_event_id, references(:pools)
    end
  end
end
