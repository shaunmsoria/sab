defmodule Sab.Repo.Migrations.CreateTokensTable do
  use Ecto.Migration

  def change do
    create table(:tokens) do
      add :symbol, :string
      add :name, :string
      add :address, :string
      add :upcase_address, :string
      add :decimals, :integer
    end
  end
end
