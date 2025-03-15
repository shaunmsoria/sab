defmodule TokenPair do
  use Ecto.Schema
  import Ecto.{Changeset, Query, Repo}

  schema "token_pairs" do
    belongs_to(:token0, Token)
    belongs_to(:token1, Token)
    has_many(:pools, Pool)
    field(:status, :string)
    field(:decimals_adjuster_0_1, :string)
  end

  @required [:token0_id, :token1_id]
  @optional [:status, :decimals_adjuster_0_1]

  def changeset(%TokenPair{} = token_pair, params) do
    token_pair
    |> cast(params, @required ++ @optional)
    |> validate_required(@required)
  end

  def update_changeset(%TokenPair{} = token_pair, params) do
    token_pair
    |> cast(params, @optional)
  end
end
