defmodule TokenPairContext do
  import Compute
  import Ecto.{Changeset, Query, Repo}
  alias TokenPairContext, as: TPC
  alias PoolContext, as: PC
  alias PoolSearch, as: PS
  alias PoolAddressContext, as: PAC

  def insert(params) do
    %TokenPair{}
    |> TokenPair.changeset(params)
    |> Repo.insert()
  end

  def update(%TokenPair{} = token_pair, params) do
    token_pair
    |> TokenPair.update_changeset(params)
    |> Repo.update()
  end

  def update_decimals_adjuster_0_1(
        %TokenPair{
          decimals_adjuster_0_1: nil
        } = token_pair
      ),
      do:
        token_pair
        |> TPC.update(%{decimals_adjuster_0_1: calculate_decimals_adjuster_0_1(token_pair)})

  def update_decimals_adjuster_0_1(
        %TokenPair{
          decimals_adjuster_0_1: _decimals_adjuster_0_1
        } = token_pair
      ),
      do: token_pair

  def maybe_add_pair_from_event_address(event_address, abi) do
    with false <- String.contains?(event_address |> inspect(), "<<"),
         {:ok, %PoolAddress{status: "new"} = pool_address} <-
           PAC.maybe_add_pool_address(event_address),
         {:ok, token0_address} <- event_address |> pool(abi, :token0),
         {:ok, token1_address} <- event_address |> pool(abi, :token1),
         {:ok, token0} <- TC.maybe_add_token(token0_address),
         {:ok, token1} <- TC.maybe_add_token(token1_address) do
      case TPS.with_token0_id(token0.id)
           |> TPS.with_token1_id(token1.id)
           |> Repo.one() do
        nil ->
          %{
            token0_id: token0.id,
            token1_id: token1.id,
            status: "inactive",
            decimals_adjuster_0_1: calculate_decimals_adjuster_0_1(token0, token1)
          }
          |> TPC.insert()

        %TokenPair{id: token_pair_id} = token_pair ->
          token_pair
          |> TPC.update(%{
            status: PC.maybe_activate_token_pair(token_pair),
            decimals_adjuster_0_1: calculate_decimals_adjuster_0_1(token_pair)
          })
      end
    else
      {:ok, %PoolAddress{status: "active"} = pool_address} ->
        preloaded_pool_address = pool_address |> Repo.preload(pool: :token_pair)
        {:ok, preloaded_pool_address.pool.token_pair}

      {:ok, %PoolAddress{status: "inactive"} = pool_address} ->
        {:error, "PoolAddress #{event_address} is in status inactive from maybe_add_pair_from_event_address"}

      error ->
        {:error, "Error from maybe_add_pair_from_event_address: #{inspect(error)}"}
    end
  end

  def test() do
    token0 = TokenSearch.with_id(5) |> Repo.one()
    token1 = TokenSearch.with_id(6) |> Repo.one()
    dex1 = DexSearch.with_id(1) |> Repo.one()
    dex2 = DexSearch.with_id(2) |> Repo.one()

    token_pair =
      TokenPairSearch.with_id(9)
      |> Repo.one()
      |> Repo.preload([:token0, :token1])

    # |> TokenPairContext.update(%{dexs: [dex2], status: "test"})

    # TokenPairContext.insert(%{token0_id: 5, token1_id: 6, dexs: [dex], status: "test"})
  end
end
