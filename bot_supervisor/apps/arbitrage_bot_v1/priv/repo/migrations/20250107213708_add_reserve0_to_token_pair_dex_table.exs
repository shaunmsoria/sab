defmodule Repo.Migrations.AddReserve0ToTokenPairDexTable do
  use Ecto.Migration

  def change do
    alter table("token_pairs_dexs") do
      add(:reserve0, :string)
    end
  end
end
