defmodule Repo.Migrations.AddV3FieldsToTokenPairDexTable do
  use Ecto.Migration

  def change do
    alter table("token_pairs_dexs") do
      add(:tick, :string)
      add(:tick_spacing, :string)
    end
  end
end
