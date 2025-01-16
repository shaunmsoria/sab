defmodule InitialiseDexTokenPair do
  import Compute
  alias PoolV2Context, as: PV2C
  alias PoolV3Context, as: PV3C
  alias DexSearch, as: DS

  def run() do
    IO.puts("sx1 IDTP before with")

    with {:ok, list_dex_token_pairs_length_updated} <- PV2C.initialise(),
         {:ok, :test} <- PV3C.initialise() do
      IO.puts("sx1 in IDTP.run")

      {:ok, :database_ready}
    end
  end
end
