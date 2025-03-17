defmodule PoolV2Context do
  import Compute
  alias PoolV2CheckProfit, as: PV2CP
  alias DexSearch, as: DS

  @doc """
    Initialise pool v2 pool
  """
  def initialise(), do: PoolV2Initialise.run()

  @doc """
    Check if pool v2 event is profitable
  """
  def check_profit(
        %Pool{} = pool,
        {amount0_in, amount0_out, amount1_in, amount1_out}
      ),
      do: PV2CP.run(pool, {amount0_in, amount0_out, amount1_in, amount1_out})

  def maybe_add_all_pool_v2(%TokenPair{} = token_pair, %PoolAddress{} = pool_address) do
    list_pools =
    DS.with_abi("uniswapV2")
    |> Repo.all()
    |> Enum.map(fn dex_v2 ->
      maybe_create_pool_v2(token_pair, pool_address, dex_v2)
    end)
    |> Enum.filter(fn maybe_pool ->
      not is_nil(maybe_pool)
    end)

    {:ok, list_pools}
  end

  def maybe_create_pool_v2(%TokenPair{} = token_pair, %PoolAddress{} = pool_address, %Dex{} = dex) do
    with false <- String.contains?(pool_address.address |> inspect(), "<<"),
         {:ok, price, reserve0, reserve1} <-
           calculate_price(pool_address.address),
         {:ok, pool} <-
           PC.maybe_add_pool(pool_address, token_pair.token0, token_pair.token1, dex, %{
             pool_address: pool_address,
             address: pool_address.address,
             upcase_address: pool_address.address |> String.upcase(),
             price: "#{price}",
             reserve0: "#{reserve0}",
             reserve1: "#{reserve1}",
             refresh_reserve: false
           })
           |> IO.inspect(label: "mx1 maybe_add_pool") do
      pool
    else
      error_message ->
        nil
    end
  end
end
