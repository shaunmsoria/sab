defmodule Repo.Migrations.AddRefreshReserveToTokenPairDexsTable do
  use Ecto.Migration

  def change do
    alter table("token_pairs_dexs") do
      add(:refresh_reserve, :boolean, default: true)
    end
  end
end
