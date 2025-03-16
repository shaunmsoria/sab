defmodule PoolV2Context do
  alias PoolV2CheckProfit, as: PV2CP

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

    ##TODO finish this function
  def maybe_add_all_pool_v2(%TokenPair{} = token_pair, %PoolAddress{} = pool_address) do

    ##TODO need to iterate over all the v2 dexs in the database
    with  false <- String.contains?(pool_address.address |> inspect(), "<<"),
    {:ok, price, reserve0, reserve1} <-
      calculate_price(pair_address),
    {:ok, pool} <- PC.maybe_add_pool(pool_address, token0, token1, dex, %{
     pool_address: pool_address,
      address: pool_address.address,
      upcase_address: pool_address.address |> String.upcase(),
      price: "#{price}",
      reserve0: "#{reserve0}",
      reserve1: "#{reserve1}",
      refresh_reserve: false
    }) |> IO.inspect(label: "mx1 maybe_add_pool") do
      ##TODO return something
      :nil
    end
  end
end
