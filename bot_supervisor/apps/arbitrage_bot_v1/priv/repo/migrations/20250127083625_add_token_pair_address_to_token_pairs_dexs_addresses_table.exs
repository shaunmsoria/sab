defmodule Repo.Migrations.AddTokenPairAddressToTokenPairsDexsAddressesTable do
  use Ecto.Migration

  def change do
    alter table("token_pairs_dexs_addresses") do
      add :token_pair_address_id, references(:token_pairs_addresses)
    end
  end
end
