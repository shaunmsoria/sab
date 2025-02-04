defmodule Repo.Migrations.RenameAddressesToTokenPairsAddressesTable do
  use Ecto.Migration

  def change do
    rename table(:addresses), to: table(:token_pairs_addresses)
  end
end
