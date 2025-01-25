defmodule TokenPair do
  use Ecto.Schema
  import Ecto.{Changeset, Query, Repo}

  schema "token_pairs" do
    belongs_to(:token0, Token)
    belongs_to(:token1, Token)
    field(:status, :string)
    field(:decimals_adjuster_0_1, :string)
    many_to_many(:dexs, Dex, join_through: "token_pairs_dexs")
  end

  @required [:token0_id, :token1_id]
  @optional [:status, :decimals_adjuster_0_1]

  def changeset(%TokenPair{} = token_pair, %{dexs: list_dexs} = params) do
    token_pair
    |> cast(params, @required ++ @optional)
    |> put_assoc(:dexs, list_dexs)
    |> validate_required(@required)
  end

  def update_changeset(%TokenPair{} = token_pair, %{dexs: new_list_dexs} = params) do
    with current_list_dexs <- token_pair |> Repo.preload(:dexs) |> Map.get(:dexs) do
      token_pair
      |> cast(params, @optional)
      |> put_assoc(:dexs, current_list_dexs ++ new_list_dexs)
    end
  end
end
