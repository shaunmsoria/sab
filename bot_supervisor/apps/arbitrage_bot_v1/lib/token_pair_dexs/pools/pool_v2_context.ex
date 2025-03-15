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
end
