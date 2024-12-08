defmodule TokenPairDex do
  use Ecto.Schema
  import Ecto.{Changeset, Query}

  schema "token_pairs_dexs" do
    belongs_to(:token_pair, TokenPair)
    belongs_to(:dex, Dex)
    field(:address, :string)
    field(:price, :string)
    field(:upcase_address, :string)

  end

  @required [:token_pair_id, :dex_id]
  @optional [:address, :price, :upcase_address]

  def update_changeset(%TokenPairDex{} = token_pair_dex, params) do
    token_pair_dex
    |> cast(params, @optional)
  end
end
