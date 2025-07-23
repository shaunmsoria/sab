defmodule PoolContext do
  @moduledoc """
    gather tools that can be used to v2 and v3 pools management
  """

  import Compute
  import Ecto.{Changeset, Query}
  alias PoolSearch, as: PS
  alias PoolContext, as: PC
  alias DexSearch, as: DS
  alias LogWritter, as: LW
  alias TokenPairSearch, as: TPS
  alias TokenPairContext, as: TPC
  alias TokenSearch, as: TS
  alias PoolAddressContext, as: PAC
  alias PoolV2Context, as: PV2C
  alias PoolV3Context, as: PV3C
  alias TokenContext, as: TC

  def insert(params) do
    %Pool{}
    |> Pool.changeset(params)
    |> Repo.insert()
    |> IO.inspect(label: "mx1 Repo.insert Pool.insert()")
  end

  def update(%Pool{} = pool, params) do
    pool
    |> Pool.update_changeset(params)
    |> Repo.update()
  end

  def update_with_token_pair_and_dex(%TokenPair{id: token_pair_id}, %Dex{id: dex_id}, params) do
    with %Pool{} = pool <-
           PS.with_token_pair_id(token_pair_id) |> PS.with_dex_id(dex_id) |> Repo.one() do
      pool
      |> PoolContext.update(params)
    end
  end

  def extract_other_pools(
        %TokenPair{id: token_pair_id} = token_pair,
        %Dex{id: dex_id, name: dex_name} = dex
      ) do
    list_pools =
      PS.with_token_pair_id(token_pair_id)
      |> Repo.all()

    filtered_pools =
      list_pools
      |> Enum.map(fn pool -> pool |> Repo.preload([:dex, :token_pair]) end)
      |> Enum.filter(fn %Pool{dex: %Dex{id: dex_id_searched}} ->
        dex_id_searched != dex_id
      end)

    case filtered_pools do
      [] ->
        {:error, "no_profitable_trades"}

      filtered_pools ->
        {:ok, filtered_pools}
    end
  end

  def update_pool_price(%Pool{} = pool),
    do: update_pool_price(pool, :pool_search)

  def update_pool_price(
        %Pool{
          dex: %Dex{abi: "uniswapV2", name: dex_name},
          refresh_reserve: false
        } = pool,
        test
      ) do
    LW.ipt("#{test} id: #{pool.id} on Dex: #{dex_name}  refresh_reserve: false, not updated")
    {:error, "refresh_reserve: false"}
  end

  def update_pool_price(
        %Pool{
          id: pool_id,
          address: pool_address,
          price: pool_price,
          dex: %Dex{abi: "uniswapV2", name: dex_name},
          refresh_reserve: true
        } = pool,
        test
      ) do
    with {:ok, new_pool_price, reserve0, reserve1} <-
           calculate_price(pool_address),
         true <-
           pool_price != "#{new_pool_price}",
         {:ok, updated_pool} <-
           PC.update(pool, %{
             price: "#{new_pool_price}",
             reserve0: "#{reserve0}",
             reserve1: "#{reserve1}",
             refresh_reserve: false
           }) do
      LW.ipt("#{test} id: #{pool_id} on Dex: #{dex_name}  price updated to: #{new_pool_price}")

      {:ok, updated_pool}
    else
      _error ->
        if test == :pool_event do
          {:error, "price same as db"}
        else
          LW.ipt("#{test} id: #{pool_id} on Dex: #{dex_name}  price not updated: #{pool_price}")

          {:ok, pool}
        end
    end
  end

  def update_pool_price(
        %Pool{
          token_pair: %TokenPair{
            decimals_adjuster_0_1: decimals_adjuster_0_1,
            token0: %Token{decimals: decimals0},
            token1: %Token{decimals: decimals1}
          },
          dex: %Dex{abi: "uniswapV3"} = dex
        } = pool,
        test
      ) do
    with {:ok, liquidity} <-
           pool(pool.address, "uniswapV3", :liquidity),
         {:ok,
          [
            sqrtPriceX96,
            tick_current,
            _observationIndex,
            _observationCardinality,
            _observationCardinalityNext,
            _feeProtocol,
            _unlocked
          ]} <-
           pool(pool.address, "uniswapV3", :slot0),
         {new_pool_price, reserve0, reserve1} <-
           PV3C.calculate_price_reserve0_reserve1(
             liquidity,
             sqrtPriceX96,
             tick_current,
             pool.tick_spacing,
             decimals_adjuster_0_1,
             decimals0,
             decimals1
           ),
         {:ok, updated_pool} <-
           PC.update(pool, %{
             price: "#{new_pool_price}",
             reserve0: "#{reserve0}",
             reserve1: "#{reserve1}",
             liquidity: "#{liquidity}",
             tick: "#{tick_current}"
           }) do
      LW.ipt("#{test} id: #{pool.id} on Dex: #{dex.name}  price updated to: #{new_pool_price}")

      {:ok, updated_pool}
    else
      error ->
        LW.ipt(
          "#{test} id: #{pool.id} on Dex: #{dex.name}  price not updated: #{pool.price}, reason: #{inspect(error)}"
        )

        {:ok, pool}
    end
  end

  def maybe_add_pool(
        %PoolAddress{
          id: pool_address_id,
          address: pool_address_address
        } = pool_address,
        %Token{id: token0_id} = token0,
        %Token{id: token1_id} = token1,
        %Dex{id: dex_v3_id} = dex,
        params
      ) do
    IO.puts("sx1 in maybe_add_pool")

    case TPS.with_token0_id(token0_id)
         |> TPS.with_token1_id(token1_id)
         |> Repo.one()
         |> IO.inspect(label: "sx1 search result for token_pair") do
      nil ->
        with {:ok, %TokenPair{} = token_pair} <-
               %{
                 token0_id: token0_id,
                 token1_id: token1_id,
                 status: "inactive",
                 decimals_adjsuter_0_1: calculate_decimals_adjuster_0_1(token0, token1)
               }
               |> TPC.insert()
               |> IO.inspect(label: "sx1 TPC insert result"),
             {:ok, pool} <-
               %Pool{}
               |> PoolContext.insert(
                 params
                 |> Map.merge(%{token_pair: token_pair})
               )
               |> IO.inspect(label: "sx1 PC insert") do
          pool_address
          |> PAC.activate(%{pool_id: pool.id})

          {:ok, pool}
        end

      %TokenPair{id: token_pair_id} = token_pair ->
        with {:ok, %TokenPair{} = updated_token_pair} <-
               token_pair
               |> TPC.update(%{
                 status: maybe_activate_token_pair(token_pair),
                 decimals_adjuster_0_1: calculate_decimals_adjuster_0_1(token_pair)
               })
               |> IO.inspect(label: "sx1 TPC.update"),
             result_pool <-
               PS.with_pool_address_id(pool_address_id)
               |> PS.with_token_pair_id(token_pair_id)
               |> PS.with_dex_id(dex_v3_id)
               |> Repo.one()
               |> IO.inspect(label: "sx1 PS search") do
          case result_pool do
            nil ->
              {:ok, pool} =
                PC.insert(
                  params
                  |> Map.merge(%{
                    token_pair: token_pair,
                    dex: dex,
                    pool_address: pool_address
                  })
                )
                |> IO.inspect(label: "sx1 PC.insert")

              pool_address
              |> PAC.activate(%{pool_id: pool.id})

              {:ok, pool}

            %Pool{} = pool ->
              pool
              |> PC.update(params)
              |> IO.inspect(label: "sx1 pool updated with params: #{inspect(params)}")
          end
        end
    end
  end

  def maybe_activate_token_pair(%TokenPair{id: token_pair_id, status: token_pair_status}) do
    list_token_pair =
      PS.with_token_pair_id(token_pair_id)
      |> Repo.all()

    case length(list_token_pair) > 1 do
      true -> "active"
      false -> token_pair_status
    end
  end

  def maybe_add_pool_from_pool_address(pool_address, %{
        "amount0" => amount0_delta,
        "amount1" => amount1_delta,
        "liquidity" => liquidity,
        "recipient" => _recipient,
        "sender" => _sender,
        "sqrtPriceX96" => sqrtPriceX96,
        "tick" => tick
      }) do
    IO.puts("sx1 in pool v3 maybe_add_pool_from_pool_address")

    with {:ok, %TokenPair{} = token_pair} <-
           TPC.maybe_add_pair_from_event_address(pool_address.address, "uniswapV3"),
         {:ok, list_pools} <- PV3C.maybe_add_all_pool_v3(token_pair, pool_address) do
      find_pool_in_list_pool(pool_address, list_pools)
    end
  end

  def maybe_add_pool_from_pool_address(pool_address, %{
        "amount0In" => amount0_in,
        "amount0Out" => amount0_out,
        "amount1In" => amount1_in,
        "amount1Out" => amount1_out,
        "sender" => _sender_address,
        "to" => _to_address
      }) do
    IO.puts("sx1 in pool v2 maybe_add_pool_from_pool_address")

    with {:ok, %TokenPair{} = token_pair} <-
           TPC.maybe_add_pair_from_event_address(pool_address.address, "uniswapV2"),
         {:ok, list_pools} <- PV2C.maybe_add_all_pool_v2(token_pair, pool_address) do
      find_pool_in_list_pool(pool_address, list_pools)
    end
  end

  def find_pool_in_list_pool(pool_address, []), do: "pool not created"

  def find_pool_in_list_pool(pool_address, list_pools) do
    pool =
      list_pools
      |> Enum.filter(fn pool ->
        pool.pool_address_id === pool_address.id
      end)
      |> Enum.at(0)

    if not is_nil(pool) do
      {:ok, pool}
    else
      "pool not created"
    end
  end
end
