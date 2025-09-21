defmodule Repo.Migrations.AddTimestampToPoolAddressTable do
  use Ecto.Migration

  def change do
    alter table(:pool_addresses) do
      add :inserted_at, :utc_datetime_usec, default: fragment("(now() - interval '1 day')")
      add :updated_at, :utc_datetime_usec, default: fragment("(now() - interval '1 day')")

      # timestamps()
    end
  end
end
