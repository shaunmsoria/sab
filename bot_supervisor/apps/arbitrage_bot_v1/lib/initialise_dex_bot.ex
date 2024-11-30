defmodule InitialiseDexBot do
  import Compute
  alias LogWritter, as: LW
  alias StateConstructor, as: SC
  alias InitialiseDexTokenPair, as: IDTP

  @dexs Libraries.dexs()
  @tokens Libraries.tokens()
  @balancer Libraries.balancer()

  def run(_state) do
    ConCache.put(:system, :new_start, true)
    ConCache.put(:dex, "list_dex", @dexs |> Map.keys())

    with {:ok, state} <- SC.run(),
         {:ok, :database_ready} <- IDTP.run() do
      state
    end
  end
end
