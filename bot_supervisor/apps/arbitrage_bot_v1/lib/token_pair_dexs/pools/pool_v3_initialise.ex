defmodule PoolV3Initialise do
  import Compute
  alias DexSearch, as: DS
  alias TokenPairDexSearch, as: TPDS

  ## TODO create pool_context_v3 to manage pool v3 initialisation, creation, referencing, **deletion
  ## TODO ** -> if necessary

  def run() do
    with list_dexs_v3 <- DS.with_abi("uniswapV3") |> Repo.all(),
         {:ok, updated_list_pool_v3} <- update_v3_pools_from_v2_pools(list_dexs_v3) do
      list_dexs_v3 |> IO.inspect(label: "sx1 list_dexs_v3")
    end

    {:ok, :test}
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

    dex_v3_n_pairs = sanitise_n_pairs(dex_v3_n_pairs_raw)
    dex_v2_n_pairs = sanitise_n_pairs(dex_v2_n_pairs_raw)

    if dex_v3_n_pairs < dex_v2_n_pairs do
      dex_v3_n_pairs..dex_v2_n_pairs
      |> Enum.map(fn n_pair ->
        maybe_get_or_create_pool_v3(dex_v3, dex_v2_id, n_pair)
        |> case do
          {:ok, pool_v3_n_pair} ->
            pool_v3_n_pair

          {:error, message} ->
            message |> LW.ipt("error for pool on dex #{dex_v2_id} for n_pair: #{n_pair}")
        end
      end)
      |> List.flatten()
    end
  end

  def sanitise_n_pairs(nil), do: 0
  def sanitise_n_pairs(0), do: 0
  def sanitise_n_pairs(n_pair) when is_integer(n_pair), do: n_pair - 1

  @pool_v3_fees ["100", "500", "3000", "10000"]
  def maybe_get_or_create_pool_v3(
        %Dex{
          id: dex_v3_id,
          factory: dex_v3_factory
        } = dex_v3,
        dex_v2_id,
        n_pair
      )
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
          id: token_pair_id,
          token0: %Token{symbol: token0_symbol, address: token0_address},
          token1: %Token{symbol: token1_symbol, address: token1_address}
        }
      } = token_pair_dex_v2 ->
        n_pair
        |> IO.inspect(label: "sx1 n_pair")

        @pool_v3_fees
        |> Enum.map(fn pool_v3_fee ->
          pool_v3_fee
          |> IO.inspect(label: "sx1 pool_v3_fee")

          token0_symbol
          |> IO.inspect(label: "sx1 token0_symbol")

          token1_symbol
          |> IO.inspect(label: "sx1 token1_symbol")

          get_pool_address(
            dex_v3_factory,
            token0_address,
            token1_address,
            pool_v3_fee |> String.to_integer()
          )
          |> case do
            {:ok, new_pool_v3_address} ->
              new_pool_v3_address
          |> IO.inspect(label: "sx1 pool_address")




            nil ->
              LW.ipt(
                "no pool v3 for token_pair_id: #{token_pair_id} with dex_id: #{dex_v3_id} and fee: #{pool_v3_fee}"
              )
          end
          |> IO.inspect(label: "sx1 get_pool_address")
        end)

        {:ok, :do_something}
    end
  end
end
