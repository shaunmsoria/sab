defmodule Repo.Migrations.RemoveVersionFromTableDexs do
  use Ecto.Migration

  def change do
    alter table("dexs") do
      remove(:version)
    end
  end
end
