defmodule Repo.Migrations.RenameTokenPairAddressIdToPoolAddressIdInPoolsTable do
  use Ecto.Migration

  def change do
    rename table(:pools), :token_pair_address_id, to: :pool_address_id
  end
end
