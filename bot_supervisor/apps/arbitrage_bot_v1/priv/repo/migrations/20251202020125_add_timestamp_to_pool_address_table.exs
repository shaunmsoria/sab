defmodule Repo.Migrations.AddTimestampToPoolAddressTable do
  use Ecto.Migration

  def change do
    alter table("pool_addresses") do
      timestamps()
    end
  end
end
