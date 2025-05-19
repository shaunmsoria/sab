defmodule Repo.Migrations.AddReserve1ToTokenPairDexTable do
  use Ecto.Migration

  def change do
    alter table("token_pairs_dexs") do
      add(:reserve1, :string)
    end
  end
end
