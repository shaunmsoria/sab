defmodule PoolAddress do
  use Ecto.Schema
  import Ecto.{Changeset, Query}

  schema "token_pairs_addresses" do
    field(:address, :string)
    field(:upcase_address, :string)
    field(:status, :string, default: "new")
    # belongs_to(:token_pair_dex_address, TokenPairDexAddress)
    has_one(:pool, Pool)
  end

  @required [:address, :upcase_address]
  @optional [
    :status,
    # :token_pair_dex_address_id
  ]

  def changeset(%PoolAddress{} = token_pair_address,  params) do
    token_pair_address
    |> cast(params, @required ++ @optional)
    |> validate_required(@required)
  end


  def update_changeset(%PoolAddress{} = token_pair_address, params) do
    token_pair_address
    |> cast(params, @optional)
  end


end
