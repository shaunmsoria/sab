defmodule InitialiseDexBot do
  import Compute
  alias LogWritter, as: LW
  alias InitialiseDexTokenPair, as: IDTP

  @dexs Libraries.dexs()
  @tokens Libraries.tokens()
  @balancer Libraries.balancer()

  def run(state) do
    ConCache.put(:system, :new_start, true)
    # ConCache.put(:dex, "list_dex", @dexs |> Map.keys())

    #todoshaun use commented section below if using v2 and v3 initialisation
    PoolAddressContext.set_dialy_pool_address_count()

    with {:ok, :database_ready} <- IDTP.run() do
      state
    end
  end
end
