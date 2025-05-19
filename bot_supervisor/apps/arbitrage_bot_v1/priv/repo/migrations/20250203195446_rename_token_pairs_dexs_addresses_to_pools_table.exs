defmodule Repo.Migrations.RenameTokenPairsDexsAddressesToPoolsTable do
  use Ecto.Migration

  def change do
    rename table(:token_pairs_dexs_addresses), to: table(:pools)
  end
end
