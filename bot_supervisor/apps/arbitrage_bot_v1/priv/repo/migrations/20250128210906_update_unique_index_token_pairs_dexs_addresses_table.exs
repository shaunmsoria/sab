defmodule Repo.Migrations.UpdateUniqueIndexTokenPairsDexsAddressesTable do
  use Ecto.Migration

def up do
  drop_if_exists unique_index(:token_pairs_dexs_addresses, [:token_pair_id, :dex_id])
  drop_if_exists unique_index(:token_pairs_dexs, [:token_pair_id, :dex_id])
  create unique_index(:token_pairs_dexs_addresses, [:token_pair_id, :dex_id, :token_pair_address_id])
end

def down do
  # drop_if_exists unique_index(:token_pairs_dexs_addresses, [:token_pair_id, :dex_id, :token_pair_address_id])
  drop unique_index(:token_pairs_dexs_addresses, [:token_pair_id, :dex_id, :token_pair_address_id])
  # create unique_index(:token_pairs_dexs_addresses, [:token_pair_id, :dex_id])
end

end
