defmodule Repo.Migrations.CreateTokenPairTable do
  use Ecto.Migration

  def change do

    create table(:token_pairs) do
      add :token0_id, references(:tokens)
      add :token1_id, references(:tokens)
      add :status, :string
    end

    create unique_index(:token_pairs, [:token0_id, :token1_id])
  end
end
