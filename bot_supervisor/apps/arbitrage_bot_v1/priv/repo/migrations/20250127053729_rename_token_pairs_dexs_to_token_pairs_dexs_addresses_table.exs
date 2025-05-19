defmodule Repo.Migrations.RenameTokenPairsDexsToTokenPairsDexsAddressesTable do
  use Ecto.Migration

  def change do
    rename table(:token_pairs_dexs), to: table(:token_pairs_dexs_addresses)
  end
end
