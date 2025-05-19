defmodule Repo.Migrations.AddFeeToTokenPairsDexTable do
  use Ecto.Migration

  def change do
    alter table("token_pairs_dexs") do
      add(:fee, :string, default: "0")
    end
  end
end
