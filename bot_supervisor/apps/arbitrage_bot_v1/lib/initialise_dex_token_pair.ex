defmodule InitialiseDexTokenPair do
  import Compute
  alias PoolContextV2, as: PCV2
  alias PoolContextV3, as: PCV3
  alias DexSearch, as: DS

  def run() do
    IO.puts("sx1 IDTP before with")

    with {:ok, list_dex_token_pairs_length_updated} <- PCV2.initialise() do
        #  {:ok, :test} <- PCV3.initialise() do
      IO.puts("sx1 in IDTP.run")

      {:ok, :database_ready}
    end
  end
end
