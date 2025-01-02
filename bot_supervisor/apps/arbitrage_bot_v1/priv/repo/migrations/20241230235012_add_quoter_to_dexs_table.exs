defmodule Repo.Migrations.AddQuoterToDexsTable do
  use Ecto.Migration

  def change do
    alter table("dexs") do
      add(:quoter, :string)
    end
  end
end
