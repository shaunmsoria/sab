defmodule Repo.Migrations.AddDecimalsAdjuster01ToTokenPairsTable do
  use Ecto.Migration

  def change do
    alter table("token_pairs") do
      add(:decimals_adjuster_0_1, :string)
    end
  end
end
