defmodule TokenPairDex do
  use Ecto.Schema
  import Ecto.{Changeset, Query}

  schema "token_pairs_dexs" do
    belongs_to(:token_pair, TokenPair)
    belongs_to(:dex, Dex)
    field(:address, :string)
    field(:price, :string)
    field(:upcase_address, :string)
    field(:n_pair, :integer)
    field(:fee, :string, default: "0")
    field(:reserve0, :string)
    field(:reserve1, :string)
    field(:refresh_reserve, :boolean, default: true)
    field(:tick, :string)
    field(:tick_spacing, :string)
  end

  @required [:token_pair_id, :dex_id]
  @optional [
    :address,
    :price,
    :upcase_address,
    :n_pair,
    :fee,
    :reserve0,
    :reserve1,
    :refresh_reserve,
    :tick,
    :tick_spacing
  ]

  def update_changeset(%TokenPairDex{} = token_pair_dex, params) do
    token_pair_dex
    |> cast(params, @optional)
  end
end
