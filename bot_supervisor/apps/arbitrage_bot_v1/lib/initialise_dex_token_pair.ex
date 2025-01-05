defmodule InitialiseDexTokenPair do
  import Compute
  alias PoolContextV2, as: PCV2
  alias PoolContextV3, as: PCV3
  alias DexSearch, as: DS

  ## TODO
  # remove comment in get_pairs_for_dex to allow the system to update for all token_pairs

  ## TODO create pool_context_v3 to manage pool v3 initialisation, creation, referencing, **deletion
  ## TODO ** -> if necessary

  def run() do
    with {:ok, list_dex_token_pairs_length_updated} <- PCV2.initialise(),
         {:ok, :test} <- PCV3.initialise() do
      {:ok, :database_ready}
    end
  end
end
