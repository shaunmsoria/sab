defmodule PoolAddressUpdate do

  # import Compute
  alias PoolSearch, as: PS
  alias PoolAddressSearch, as: PAS
  alias PoolAddressContext, as: PAC
  alias LogWritter, as: LW



 def main() do
    # create_pool_address_for_pool()
    remove_pool_address_duplication()
 end

 def create_pool_address_for_pool() do
  ##? get all existing pools

  all_pools =
    PS.query()
    |> Repo.all()


  all_pools
  |> Enum.each(fn pool ->

    pool_address =
      pool
      |> Repo.preload(:pool_address)
      |> Map.get(:pool_address)

    case pool_address do
      nil ->
        {:ok, created_pool_address} =
          %{
            address: pool.address,
            upcase_address: String.upcase(pool.address),
            status: "active",
            pool_id: pool.id
          }
          |> PAC.insert()
          |> LW.ipt("sx1 Pool Address created")

          pool
          |> PoolContext.update(%{pool_address_id: created_pool_address.id})
          |> LW.ipt("sx1 Pool Address updated with id: #{created_pool_address.id}")

      %PoolAddress{} = pool_address ->
        LW.ipt("sx1 Pool Address: #{pool_address.id} already exists for pool: #{pool.id}")


      error ->
        LW.ipt("sx1 error: #{inspect(error)} occured to create PoolAddress of Pool: ;#{pool.id}")

    end
  end)

end

def remove_pool_address_duplication() do

  all_pool_addresses =
    PAS.query()
    |> Repo.all()
    |> Repo.preload(:pool)

    all_pool_addresses
    |> Enum.sort_by(& &1.upcase_address, :asc)
    |> Enum.reduce({[], nil}, fn pool_address, acc ->
      case not is_nil(elem(acc, 1)) and pool_address.upcase_address == elem(acc, 1).upcase_address do
        true ->
          {elem(acc, 0) ++ [{pool_address, elem(acc, 1)}], pool_address}

        false ->
          {elem(acc, 0), pool_address}
        end
    end)
    |> elem(0)
    |> Enum.each(
      fn {pool_address_1, pool_address_2} ->
        if not is_nil(pool_address_1.pool.n_pair) do
          pool_address_2
          |> PAC.inactivate()
          |> LW.ipt("sx1 Pool Address: #{pool_address_2.id} inactivated due to duplication with Pool Address: #{pool_address_1.id}")
        else
          pool_address_1
          |> PAC.inactivate()
          |> LW.ipt("sx1 Pool Address: #{pool_address_1.id} inactivated due to duplication with Pool Address: #{pool_address_2.id}")
        end
    end)
      |> IO.inspect(label: "sx1 all_pool_addresses sort_by", limit: :infinity)

end



end

PoolAddressUpdate.main()
