defmodule PoolAddressContext do
  import Compute
  import Ecto.{Changeset, Query}
  alias PoolAddressContext, as: PAC
  alias PoolAddressSearch, as: PAS

  def insert(params) do
    %PoolAddress{}
    |> PoolAddress.changeset(params)
    |> Repo.insert()
  end

  def update(%PoolAddress{} = pool_address, params) do
    pool_address
    |> PoolAddress.update_changeset(params)
    |> Repo.update()
  end

  def activate(%PoolAddress{} = pool_address, %{pool_id: pool_id}) do
    pool_address
    |> PoolAddress.update_changeset(%{status: "active", pool_id: pool_id})
    |> Repo.update()
  end

  def inactivate(%PoolAddress{} = pool_address) do
    pool_address
    |> PoolAddress.update_changeset(%{status: "inactive"})
    |> Repo.update()
  end

  def maybe_add_pool_address(event_address) do
    upcase_event_address = String.upcase(event_address)

    case PAS.with_upcase_address(upcase_event_address)
         |> Repo.one() do
      nil ->
        with {:ok, pool_address} <-
               %{
                 address: event_address,
                 upcase_address: upcase_event_address,
                 status: "new"
               }
               |> PAC.insert() do
          {:ok, pool_address}
        end

      %PoolAddress{status: "inactive"} = pool_address ->
        {:error, "PoolAddress #{event_address} is in status #{status}"}

      %PoolAddress{status: status} = pool_address ->
        {:ok, pool_address}
    end
  end
end
