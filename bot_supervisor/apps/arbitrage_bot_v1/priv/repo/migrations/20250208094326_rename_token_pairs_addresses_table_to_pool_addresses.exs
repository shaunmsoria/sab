defmodule Repo.Migrations.RenameTokenPairsAddressesTableToPoolAddresses do
  use Ecto.Migration

  def change do
      rename table(:token_pairs_addresses), to: table(:pool_addresses)
    end
end
