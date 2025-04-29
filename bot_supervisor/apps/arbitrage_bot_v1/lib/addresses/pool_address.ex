defmodule PoolAddress do
  use Ecto.Schema
  import Ecto.{Changeset, Query}

  schema "pool_addresses" do
    field(:address, :string)
    field(:upcase_address, :string)
    field(:status, :string, default: "new")
    belongs_to(:pool, Pool)
  end

  @required [:address, :upcase_address]
  @optional [
    :status,
    :pool_id
  ]

  def changeset(%PoolAddress{} = pool_address, params) do
    pool_address
    |> cast(params, @required ++ @optional)
    |> validate_required(@required)
  end

  def update_changeset(%PoolAddress{} = pool_address, params) do
    pool_address
    |> cast(params, @optional)

    # |> put_assoc(:pool, params[:pool_id])
  end
end
