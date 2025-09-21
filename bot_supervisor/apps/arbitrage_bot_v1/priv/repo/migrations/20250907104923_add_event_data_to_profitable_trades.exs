defmodule Repo.Migrations.AddEventDataToProfitableTrades do
  use Ecto.Migration

  def change do
    alter table(:profitable_trades) do
      add :event_data, :map
    end
  end
end
