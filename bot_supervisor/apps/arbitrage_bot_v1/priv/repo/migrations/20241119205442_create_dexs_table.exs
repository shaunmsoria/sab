defmodule Repo.Migrations.CreateDexsTable do
  use Ecto.Migration

  def change do
    create table(:dexs) do
      add :name, :string
      add :router, :string
      add :factory, :string
      add :version, :integer
      add :all_pairs_length, :integer
    end
  end
end
