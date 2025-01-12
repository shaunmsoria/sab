defmodule PoolV2Context do



  @doc """
  Initialise pool v2 token_pair_dex
  """
  def initialise(), do: PoolV2Initialise.run()

end
