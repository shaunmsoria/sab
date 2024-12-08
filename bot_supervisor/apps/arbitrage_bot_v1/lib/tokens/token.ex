defmodule Token do
  use Ecto.Schema
  import Ecto.{Changeset, Query}

  schema "tokens" do
    field(:symbol, :string)
    field(:name, :string)
    field(:address, :string)
    field(:decimals, :integer, default: 0)
  end

  @required [:address]
  @optional [:symbol, :name, :decimals]

  def changeset(%Token{} = token, params \\ %{}) do
    token
    |> cast(params, @required ++ @optional)
    |> validate_required(@required)
  end
end
