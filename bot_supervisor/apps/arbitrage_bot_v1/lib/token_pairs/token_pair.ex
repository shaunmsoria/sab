defmodule TokenPair do
  use Ecto.Schema
  import Ecto.{Changeset, Query}

  schema "token_pairs" do
    belongs_to(:token0, Token)
    belongs_to(:token1, Token)
    field(:status, :string)
    many_to_many(:dexs, Dex, join_through: "token_pairs_dexs")
  end

  @required [:token0, :token1]
  @optional [:status]

  def changeset(%TokenPair{} = token_pair, %{token0: token0, token1: token1, dexs: list_dexs} = params) do
    token_pair
    |> cast(params, @optional)
    |> put_assoc(:token0, token0)
    |> put_assoc(:token1, token1)
    |> put_assoc(:dexs, list_dexs)
    |> validate_required(@required)
  end
end
