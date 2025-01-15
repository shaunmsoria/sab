defmodule TokenContext do
  import Ecto.{Changeset, Query}

  def insert(params) do
    %Token{}
    |> Token.changeset(params)
    |> Repo.insert()
  end

  def update(%Token{} = token, params) do
    token
    |> Token.changeset(params)
    |> Repo.update()
  end

  def test2() do
    from(t in "tokens", select: t.id)
    |> Repo.all()
  end
end
