defmodule Repo.Migrations.CreateTokenPairsDexsTable do
  use Ecto.Migration

  def change do
    create table(:token_pairs_dexs) do
      add :token_pair_id, references(:token_pairs)
      add :dex_id, references(:dexs)
      add :address, :string
      add :price, :string
      add :upcase_address, :string

    end

    create unique_index(:token_pairs_dexs, [:token_pair_id, :dex_id])
  end
end
