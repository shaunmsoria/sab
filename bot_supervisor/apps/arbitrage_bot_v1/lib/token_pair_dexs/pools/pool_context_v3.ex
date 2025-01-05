defmodule PoolContextV3 do
  import Compute

  ## TODO create pool_context_v3 to manage pool v3 initialisation, creation, referencing, **deletion
  ## TODO ** -> if necessary

  def initialise() do
    with list_dexs_v3 <- DS.with_abi("uniswapV3") |> Repo.all() do
    end

    {:ok, :test}
  end
end

# DS.with_abi("uniswapV3")
# |> Repo.all()
# |> Enum.map(fn %Dex{factory: dex_factory, name: dex_name} = dex ->
#   %Dex{factory: dex_factory_v2} =
#     DS.with_name(dex_name) |> DS.with_abi("uniswapV2") |> Repo.one()

#   maybe_update_dex_all_pairs(dex, dex_factory_v2)
# end)

# def get_or_create_pair_for_dex_v3(
#       %Dex{name: dex_name, factory: dex_factory, abi: "uniswapV3"} = dex,
#       n_pair
#     ) do
#   ## TODO allow function to create pool for dex_v3
#   ## TODO need to get the dex_id of dex_v2 equivalent
#   ## TODO call the list of fee to enum on

#   %Dex{id: dex_id_v2} =
#     DS.with_name(dex_name) |> DS.with_abi("uniswapv2") |> Repo.one()

#   token_pair_dex =
#     %TokenPairDex{
#       token0: %Token{address: token0_address},
#       token1: %Token{address: token1_address}
#     } =
#     TPDS.with_n_pair(n_pair)
#     |> TPDS.with_dex_id(dex_id_v2)
#     |> TPDS.with_fee("0")
#     |> Repo.one()
#     |> Repo.preload(token_pair: [:token0, :token1])
# end
