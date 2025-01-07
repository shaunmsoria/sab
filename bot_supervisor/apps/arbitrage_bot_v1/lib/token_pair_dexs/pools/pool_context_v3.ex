defmodule PoolContextV3 do
  import Compute
  alias DexSearch, as: DS
  alias TokenPairDexSearch, as: TPDS

  ## TODO create pool_context_v3 to manage pool v3 initialisation, creation, referencing, **deletion
  ## TODO ** -> if necessary

  def initialise() do
    with list_dexs_v3 <- DS.with_abi("uniswapV3") |> Repo.all(),
         {:ok, updated_list_pool_v3} <- update_v3_pools_from_v2_pools(list_dexs_v3) do
      list_dexs_v3 |> IO.inspect(label: "sx1 list_dexs_v3")
    end

    {:ok, :test}
  end
end

def update_v3_pools_from_v2_pools(list_dexs_v3) when is_list(list_dexs_v3) do
  updated_list_pool_v3 =
    list_dexs_v3
    |> Enum.map(fn dex_v3 ->
      maybe_update_v3_pool_from_v2_pool(dex_v3)
    end)

  {:ok, updated_list_pool_v3}
end

def maybe_update_v3_pool_from_v2_pool(
      %Dex{name: dex_v3_name, abi: dex_v3_abi, all_pairs_length: dex_v3_n_pairs_raw} = dex_v3
    ) do
  dex_v2 =
    %Dex{id: dex_v2_id, all_pairs_length: dex_v2_n_pairs_raw} =
    DS.with_name(dex_v3_name) |> DS.with_abi("uniswapV2") |> Repo.one()

  dex_v3_n_pairs = sanitise_n_pairs(dex_v3_n_pairs)
  dex_v2_n_pairs = sanitise_n_pairs(dex_v2_n_pairs)

  if dex_v3_n_pairs < dex_v2_n_pairs do
    dex_v3_n_pairs..dex_v2_n_pairs
    |> Enum.map(fn n_pair ->
      {:ok, pool_v3_n_pair} = maybe_get_or_create_pool_v3(dex_v3, dex_v2_id, n_pair)
    end)
  end
end

def sanitise_n_pairs(nil), do: 0
def sanitise_n_pairs(0) when is_integer(n_pair), do: 0
def sanitise_n_pairs(n_pair) when is_integer(n_pair), do: n_pair - 1

def maybe_get_or_create_pool_v3(%Dex{} = dex_v3, dex_v2_id, n_pair)
    when is_integer(dex_v2_id) and is_integer(n_pair) do
  token_pair_dex_v2_result =
    TPDS.with_dex_id(dex_v2_id)
    |> TPDS.with_n_pair(n_pair)
    |> TPDS.with_fee("0")
    |> Repo.one()
    |> Repo.preload(token_pair: [:token0, :token1])

  case token_pair_dex_v2_result do
    nil ->
      {:error, "no_token_pair found with n_pair #{n_pair} for this dex_id #{dex_v2_id}"}

    %TokenPairDex{
      token_pair: %TokenPair{
        token0: %Token{address: token0_address},
        token1: %Token{address: token1_address}
      }
    } ->
      :do_something
  end
end

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
