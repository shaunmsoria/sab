defmodule Repo.Migrations.AddPoolIdToPoolAddressTable do
  use Ecto.Migration

  def change do
    alter table("pool_addresses") do
      add :pool_id, references(:pools)
    end
  end
end
