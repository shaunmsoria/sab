defmodule PoolV2Initialise do
  import Compute
  alias LogWritter, as: LW
  alias ListDex, as: LD
  alias DexSearch, as: DS
  alias DexContext, as: DC
  alias TokenSearch, as: TS
  alias TokenContext, as: TC
  alias TokenPairSearch, as: TPS
  alias TokenPairContext, as: TPC
  alias PoolAddressContext, as: PAC
  alias PoolAddressSearch, as: PAS
  alias PoolContext, as: PC
  alias LogWritter, as: LW

  ## TODO
  # remove comment in get_pairs_for_dex to allow the system to update for all token_pairs

  def run() do
    Repo.update_all(Pool, set: [refresh_reserve: true])

    with list_dexs_v2 <- DS.with_abi("uniswapV2") |> Repo.all(),
         {:ok, list_dex_token_pairs_length_updated} <- get_all_token_pairs_length(list_dexs_v2) do
      {:ok, list_dex_token_pairs_length_updated}
    end
  end

  def get_all_token_pairs_length(list_dexs) do
    list_processed_dexs =
      list_dexs
      |> Enum.map(fn dex ->
        maybe_update_dex_all_pairs(dex)
      end)

    {:ok, list_processed_dexs}
  end

  def maybe_update_dex_all_pairs(
        %Dex{all_pairs_length: nil, name: dex_name, factory: dex_factory} = dex
      ) do
    with {:ok, dex_all_pairs_length} <- get_all_pairs_length(dex_factory),
         {:ok, :all_pairs_retrieved} <- get_pairs_for_dex(dex, dex_all_pairs_length) do
      dex
    end
  end

  def maybe_update_dex_all_pairs(
        %Dex{
          name: dex_name,
          all_pairs_length: current_all_pairs_length,
          factory: dex_factory
        } = dex
      ) do
    with {:ok, dex_all_pairs_length} <- get_all_pairs_length(dex_factory) do
      max_length =
        case dex_name do
          "pancakeswap" -> 20
          "sushiswap" -> 20
          _ -> 20
        end

      # case dex_name do
      #   "pancakeswap" -> 681
      #   "sushiswap" -> 4143
      #   _ -> 237_720
      # end

      # if dex_all_pairs_length <= current_all_pairs_length do
      if max_length <= current_all_pairs_length do
        IO.puts("dex: #{dex_name} is up to date")
      else
        # get_pairs_for_dex(dex, dex_all_pairs_length, current_all_pairs_length + 1)
        get_pairs_for_dex(dex, max_length, current_all_pairs_length + 1)
        IO.puts("dex: #{dex_name} have been updated")
      end

      dex
    end
  end

  def sanitise_current_all_pairs_length(0), do: 0

  def sanitise_current_all_pairs_length(current_all_pairs_length),
    do: current_all_pairs_length - 1

  def get_pairs_for_dex(
        dex,
        dex_all_pairs_length,
        start_all_pairs_length \\ 0
      ) do
    sanitise_current_all_pairs_length(start_all_pairs_length)..(dex_all_pairs_length - 1)
    |> Enum.map(fn n_pair ->
      n_pair |> IO.inspect(label: "n_pair")

      get_or_create_pair_for_dex(dex, n_pair)
    end)

    {:ok, :all_pairs_retrieved}
  end

  def get_or_create_pair_for_dex(%Dex{name: dex_name, factory: dex_factory} = dex, n_pair) do
    with {:ok, pair_address} <-
           get_all_pairs(dex_factory, n_pair) |> IO.inspect(label: "sx1 get_all_pairs"),
         true <- String.valid?(pair_address),
         {:ok, pool_address, token0, token1} <-
           get_or_create_pool_address_token0_token1_from_event_address(pair_address, "uniswapV2"),
         {:ok, price, reserve0, reserve1} <-
           calculate_price(pair_address),
         {:ok, pool} <-
           PC.maybe_add_pool(pool_address, token0, token1, dex, %{
             pool_address: pool_address,
             address: pair_address,
             upcase_address: pair_address |> String.upcase(),
             n_pair: n_pair,
             price: "#{price}",
             reserve0: "#{reserve0}",
             reserve1: "#{reserve1}",
             refresh_reserve: false
           })
           |> IO.inspect(label: "mx1 maybe_add_pool"),
         {:ok, updated_dex} <- dex |> DC.update(%{all_pairs_length: n_pair}) do
      {:ok, pool}
    else
      error ->
        :timer.sleep(5000)

        LW.ipt(
          "dex: #{dex_name} for n_pair: #{n_pair} not retrieved because of: #{inspect(error)}"
        )

        get_or_create_pair_for_dex(%Dex{factory: dex_factory} = dex, n_pair + 1)
    end
  end

  def get_or_create_pool_address_token0_token1_from_event_address(event_address, abi) do
    pool_address_result =
      PAS.with_upcase_address(String.upcase(event_address))
      |> Repo.one()

    case pool_address_result do
      nil ->
        TPC.maybe_add_pair_from_event_address(event_address, "uniswapV2")
        |> case do
          {:ok, %TokenPair{} = token_pair} ->
            token_pair_preloaded =
              token_pair
              |> Repo.preload([:token0, :token1])

            pool_address =
              PAS.with_upcase_address(String.upcase(event_address))
              |> Repo.one()

            {:ok, pool_address, token_pair_preloaded.token0, token_pair_preloaded.token1}

          {:error, error} ->
            {:error, "Error from maybe_add_pair_from_event_address: #{inspect(error)}"}
        end

      %PoolAddress{status: "new"} = pool_address ->
        TPC.maybe_add_pair_from_event_address(event_address, "uniswapV2")
        |> case do
          {:ok, %TokenPair{} = token_pair} ->
            token_pair_preloaded =
              token_pair
              |> Repo.preload([:token0, :token1])

            updated_pool_address =
              PAS.with_id(pool_address.id)
              |> Repo.one()

            {:ok, updated_pool_address, token_pair_preloaded.token0, token_pair_preloaded.token1}

          {:error, error} ->
            {:error, "Error from maybe_add_pair_from_event_address: #{inspect(error)}"}
        end

      %PoolAddress{status: "active"} = pool_address ->
        preloaded_pool_address =
          pool_address |> Repo.preload(pool: [token_pair: [:token0, :token1]])

        {:ok, pool_address, preloaded_pool_address.pool.token_pair.token0,
         preloaded_pool_address.pool.token_pair.token1}

      %PoolAddress{status: "inactive"} ->
        {:error,
         "PoolAddress #{event_address} is in status inactive from maybe_add_pair_from_event_address"}
    end
  end

  # def get_or_create_pair_for_dex(%Dex{name: dex_name, factory: dex_factory} = dex, n_pair) do
  #   with {:ok, pair_address} <-
  #          get_all_pairs(dex_factory, n_pair) |> IO.inspect(label: "sx1 get_all_pairs"),
  #        false <- String.contains?(pair_address |> inspect(), "<<"),
  #        {:ok, %PoolAddress{id: pool_address_id} = pool_address} <- PAC.maybe_add_pool_address(pair_address),
  #        {:ok, token0_address} <- pair_address |> pool("uniswapV2", :token0),
  #        {:ok, token1_address} <- pair_address |> pool("uniswapV2", :token1),
  #        {:ok, token0} <- TC.maybe_add_token(token0_address),
  #        {:ok, token1} <- TC.maybe_add_token(token1_address),
  #        {:ok, price, reserve0, reserve1} <-
  #          calculate_price(pair_address),
  #        {:ok, pool} <- PC.maybe_add_pool(pool_address, token0, token1, dex, %{
  #         pool_address: pool_address,
  #          address: pair_address,
  #          upcase_address: pair_address |> String.upcase(),
  #          n_pair: n_pair,
  #          price: "#{price}",
  #          reserve0: "#{reserve0}",
  #          reserve1: "#{reserve1}",
  #          refresh_reserve: false
  #        }) |> IO.inspect(label: "mx1 maybe_add_pool"),
  #        {:ok, updated_dex} <- dex |> DC.update(%{all_pairs_length: n_pair}) do
  #     {:ok, pool}
  #   else
  #     error ->
  #       :timer.sleep(5000)

  #       LW.ipt(
  #         "dex: #{dex_name} for n_pair: #{n_pair} not retrieved because of: #{inspect(error)}"
  #       )

  #       get_or_create_pair_for_dex(%Dex{factory: dex_factory} = dex, n_pair + 1)
  #   end
  # end

  #   def get_or_create_pair_for_dex(%Dex{name: dex_name, factory: dex_factory} = dex, n_pair) do
  #   with {:ok, pair_address} <-
  #          get_all_pairs(dex_factory, n_pair) |> IO.inspect(label: "sx1 get_all_pairs"),
  #        false <- String.contains?(pair_address |> inspect(), "<<"),
  #        {:ok, %PoolAddress{id: pool_address_id} = pool_address} <- PAC.maybe_add_pool_address(pair_address),
  #        {:ok, token0_address} <- pair_address |> pool("uniswapV2", :token0),
  #        {:ok, token1_address} <- pair_address |> pool("uniswapV2", :token1),
  #        {:ok, token0} <- TC.maybe_add_token(token0_address),
  #        {:ok, token1} <- TC.maybe_add_token(token1_address),
  #        {:ok, price, reserve0, reserve1} <-
  #          calculate_price(pair_address),
  #        {:ok, pool} <- PC.maybe_add_pool(pool_address, token0, token1, dex, %{
  #         pool_address: pool_address,
  #          address: pair_address,
  #          upcase_address: pair_address |> String.upcase(),
  #          n_pair: n_pair,
  #          price: "#{price}",
  #          reserve0: "#{reserve0}",
  #          reserve1: "#{reserve1}",
  #          refresh_reserve: false
  #        }) |> IO.inspect(label: "mx1 maybe_add_pool"),
  #        {:ok, updated_dex} <- dex |> DC.update(%{all_pairs_length: n_pair}) do
  #     {:ok, pool}
  #   else
  #     error ->
  #       :timer.sleep(5000)

  #       LW.ipt(
  #         "dex: #{dex_name} for n_pair: #{n_pair} not retrieved because of: #{inspect(error)}"
  #       )

  #       get_or_create_pair_for_dex(%Dex{factory: dex_factory} = dex, n_pair + 1)
  #   end
  # end
end
