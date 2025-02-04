defmodule PoolAddressContext do
  import Compute
  import Ecto.{Changeset, Query}
  alias PoolAddressContext, as: PAC
  alias PoolAddressSearch, as: PAS

  def insert(params) do
    %PoolAddress{}
    |> PoolAddress.changeset(params)
    |> Repo.insert()
  end

  def update(%PoolAddress{} = token_pair_address, params) do
    token_pair_address
    |> TokenPairToken.update_changeset(params)
    |> Repo.update()
  end

  def maybe_add_token_pair_address(pair_address) do
    upcase_pair_address = String.upcase(pair_address)

    case PAS.with_upcase_address(upcase_pair_address)
         |> Repo.one() do
      nil ->
        with {:ok, token_pair_address} <-
               %{
                 address: pair_address,
                 upcase_address: upcase_pair_address,
                 status: "new"
               }
               |> PAC.insert() do
          {:ok, token_pair_address}
        end

      %PoolAddress{status: "deprecated"} = token_pair_address ->
        {:error, "PoolAddress #{pair_address} is in status deprecated"}

      %PoolAddress{status: _status} = token_pair_address ->
        {:ok, token_pair_address}
    end
  end
end
