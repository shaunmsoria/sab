defmodule Repo.Migrations.CreateAddressesTable do
  use Ecto.Migration

  def change do
    create table(:addresses) do
      add :address, :string
      add :upcase_address, :string
      add :status, :string, default: "new"
      # add :token_pair_dex_address_id, references(:token_pairs_dexs_addresses)
    end

    # create unique_index(:token_pairs_dexs_addresses, [:upcase_address])
  end
end
