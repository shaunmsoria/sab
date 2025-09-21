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
        {:error, "PoolAddress #{event_address} is in status inactive"}

      %PoolAddress{status: status} = pool_address ->
        {:ok, pool_address}
    end
  end

  # ? TokenPair status is resolved in the TokenPair update later in the code
  def maybe_activate_pool_address(
        %PoolAddress{} = pool_address,
        %TokenPair{} = token_pair
      ),
      do:
        token_pair
        |> Repo.preload(:pools)
        |> Map.get(:pools)
        |> Enum.filter(fn pool ->
          pool.upcase_address == pool_address.upcase_address
        end)
        |> List.first()
        |> resolve_pool_address_update(pool_address, token_pair)

  def resolve_pool_address_update(nil, %PoolAddress{status: "new"} = pool_address, %TokenPair{
        status: token_pair_status
      })
      when token_pair_status in ["active", "inactive"] do
    set_dialy_pool_address_count()
    inactivate(pool_address)
  end

  def resolve_pool_address_update(
        %Pool{} = pool,
        %PoolAddress{status: "new"} = pool_address,
        %TokenPair{status: token_pair_status} = token_pair
      )
      when token_pair_status in ["active", "inactive"] do
    PoolContext.update(pool, %{pool_address_id: pool_address.id})
    set_dialy_pool_address_count()
    activate(pool_address, %{pool_id: pool.id})
  end

  def resolve_pool_address_update(_, %PoolAddress{status: _status} = pool_address, _),
    do: {:ok, pool_address}

  def set_dialy_pool_address_count() do
    date =
      Timex.today()
      |> Timex.to_naive_datetime()

    count_today_updated_pool_addresses =
      from(pa in PoolAddress,
        where: pa.status != "new",
        where: pa.updated_at >= ^date
      )
      |> Repo.aggregate(:count, :id)

    ConCache.put(:system, :daily_pool_address_count, count_today_updated_pool_addresses)

    # ConCache.get(:system, :today_updated_pool_addresses)
    # |> IO.inspect(label: "sx1 ConCache today_updated_pool_addresses")
  end
end
