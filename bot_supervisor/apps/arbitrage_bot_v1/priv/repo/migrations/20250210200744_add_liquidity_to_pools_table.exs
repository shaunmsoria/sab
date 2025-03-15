defmodule Repo.Migrations.AddLiquidityToPoolsTable do
  use Ecto.Migration

  def change do
    alter table(:pools) do
      add :liquidity, :string
    end
  end
end
