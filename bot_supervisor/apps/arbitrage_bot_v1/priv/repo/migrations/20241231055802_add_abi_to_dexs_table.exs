defmodule Repo.Migrations.AddAbiToDexsTable do
  use Ecto.Migration

  def change do
    alter table("dexs") do
      add(:abi, :string)
    end
  end
end
