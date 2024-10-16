defmodule InitialiseDexBot do
  import Compute
  alias LogWritter, as: LW
  alias StateConstructor, as: SC

  @dexs Libraries.dexs()
  @tokens Libraries.tokens()
  @balancer Libraries.balancer()

  def run(_state) do
    with {:ok, state} <- SC.run() do
      state
    end
  end
end
