defmodule Dex do
  use Ecto.Schema
  import Ecto.{Changeset, Query}

  schema "dexs" do
    field(:name, :string)
    field(:router, :string)
    field(:factory, :string)
    field(:version, :integer)
    field(:all_pairs_length, :integer)
    many_to_many(:token_pairs, TokenPair, join_through: "token_pairs_dexs")
  end

  @required [:name, :router, :factory, :version]
  @optional [:all_pairs_length]

  def changeset(%Dex{} = dex, %{} = params) do
    dex
    |> cast(params, @required ++ @optional)
    |> validate_required(@required)
  end
end
