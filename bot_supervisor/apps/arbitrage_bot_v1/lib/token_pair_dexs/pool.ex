defmodule Pool do
  use Ecto.Schema
  import Ecto.{Changeset, Query}

  schema "pools" do
    belongs_to(:token_pair, TokenPair)
    belongs_to(:token_pair_address, PoolAddress)
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

  @required []
  @optional [
    :address,
    :price,
    :upcase_address,
    :n_pair,
    :reserve0,
    :reserve1,
    :refresh_reserve,
    :tick,
    :tick_spacing,
    :fee,
  ]

  def changeset(%Pool{} = pool, %{
    token_pair: token_pair,
    dex: dex,
    token_pair_address: token_pair_address
    } = params) do



    pool
    |> cast(params, @required ++ @optional)
    |> put_assoc(:token_pair, token_pair)
    |> put_assoc(:dex, dex)
    |> put_assoc(:token_pair_address, token_pair_address)
    |> validate_required(@required)
  end

  def update_changeset(%Pool{} = pool, params) do
    pool
    |> cast(params, @optional)
  end
end
