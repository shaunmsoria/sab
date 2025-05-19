defmodule PoolAddressUpdate do

  # import Compute
  alias PoolSearch, as: PS
  alias PoolAddressSearch, as: PAS
  alias PoolAddressContext, as: PAC
  alias LogWritter, as: LW



 def main() do

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



end

PoolAddressUpdate.main()
