defmodule DexContext do
  import Ecto.{Changeset, Query}

  def insert(params) do
    %Dex{}
    |> Dex.changeset(params)
    |> Repo.insert()
  end

  def update(%Dex{} = dex, params) do
    dex
    |> Dex.changeset(params)
    |> Repo.update()
  end
end
