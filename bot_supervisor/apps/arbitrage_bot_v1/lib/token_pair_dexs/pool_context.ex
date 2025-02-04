defmodule PoolContext do
  import Compute
  import Ecto.{Changeset, Query}
  alias PoolSearch, as: PS
  alias PoolContext, as: PC
  alias DexSearch, as: DS
  alias LogWritter, as: LW
  alias TokenPairSearch, as: TPS
  alias TokenPairContext, as: TPC
  alias TokenSearch, as: TS

  def insert(params) do
    %Pool{}
    |> Pool.changeset(params)
    |> IO.inspect(label: "sx1 pre Repo.insert")
    |> Repo.insert()
    |> IO.inspect(label: "mx1 Repo.insert Pool.insert()")
  end

  def update(%Pool{} = token_pair_dex, params) do
    token_pair_dex
    |> Pool.update_changeset(params)
    |> Repo.update()
  end

  def update_with_token_pair_and_dex(%TokenPair{id: token_pair_id}, %Dex{id: dex_id}, params) do
    with %Pool{} = token_pair_dex <-
           PS.with_token_pair_id(token_pair_id) |> PS.with_dex_id(dex_id) |> Repo.one() do
      token_pair_dex
      |> PoolContext.update(params)
    end
  end

  def extract_other_pools(
        %TokenPair{id: token_pair_id} = token_pair,
        %Dex{id: dex_id, name: dex_name} = dex
      ) do
    {:ok, %{entries: list_pools}} =
      PS.with_token_pair_id(token_pair_id)
      |> Repo.all()

    filtered_pools =
      list_pools
      |> Enum.map(fn pool -> pool |> Repo.preload([:dex, :token_pair]) end)
      |> Enum.filter(fn %Pool{dex: %Dex{id: dex_id_searched}} ->
        dex_id_searched != dex_id
      end)

    case filtered_pools do
      [] ->
        {:error, "no_profitable_trades"}

        filtered_pools ->
        {:ok, filtered_pools}
    end
  end


  def update_token_pair_dex_price(%Pool{} = token_pair_dex),
    do: update_token_pair_dex_price(token_pair_dex, :TPD_searched)

  def update_token_pair_dex_price(
        %Pool{
          id: token_pair_dex_id,
          address: pool_address,
          price: nil,
          dex: %Dex{name: dex_name}
        } = token_pair_dex,
        test
      ) do
    with {:ok, new_token_pair_dex_price, reserve0, reserve1} <-
           Compute.calculate_price(pool_address),
         {:ok, updated_token_pair_dex} <-
           PC.update(token_pair_dex, %{
             price: "#{new_token_pair_dex_price}",
             reserve0: "#{reserve0}",
             reserve1: "#{reserve1}"
           }) do
      LW.ipt(
        "#{test} id: #{token_pair_dex_id} on Dex: #{dex_name} price updated to: #{new_token_pair_dex_price}"
      )

      {:ok, updated_token_pair_dex}
    else
      error ->
        {:error, error}
    end
  end

  def update_token_pair_dex_price(
        %Pool{
          id: token_pair_dex_id,
          address: pool_address,
          price: token_pair_dex_price,
          dex: %Dex{name: dex_name}
        } = token_pair_dex,
        test
      ) do
    with {:ok, new_token_pair_dex_price, reserve0, reserve1} <-
           Compute.calculate_price(pool_address),
         true <-
           token_pair_dex_price != "#{new_token_pair_dex_price}",
         {:ok, updated_token_pair_dex} <-
           PC.update(token_pair_dex, %{
             price: "#{new_token_pair_dex_price}",
             reserve0: "#{reserve0}",
             reserve1: "#{reserve1}"
           }) do
      LW.ipt(
        "#{test} id: #{token_pair_dex_id} on Dex: #{dex_name}  price updated to: #{new_token_pair_dex_price}"
      )

      {:ok, updated_token_pair_dex}
    else
      _error ->
        if test == :pool_event do
          {:error, "price same as db"}
        else
          LW.ipt(
            "#{test} id: #{token_pair_dex_id} on Dex: #{dex_name}  price not updated: #{token_pair_dex_price}"
          )

          {:ok, token_pair_dex}
        end
    end
  end

  ## TODO create the token_pair_dex_address row from token_pair_dex_address not token_pair associated with dex
  def maybe_add_token_pair_dex(
        %PoolAddress{
          id: token_pair_address_id,
          address: token_pair_address_address
        } = token_pair_address,
        %Token{id: token0_id} = token0,
        %Token{id: token1_id} = token1,
        %Dex{id: dex_v3_id} = dex,
        params
      ) do
    IO.puts("sx1 in maybe_add_token_pair_dex")

    case TPS.with_token0_id(token0_id)
         |> TPS.with_token1_id(token1_id)
         |> Repo.one()
         |> IO.inspect(label: "sx1 search result for token_pair") do
      nil ->
        with {:ok, %TokenPair{} = token_pair} <-
               %{
                 token0_id: token0_id,
                 token1_id: token1_id,
                 status: "inactive",
                 decimals_adjsuter_0_1: calculate_decimals_adjuster_0_1(token0, token1)
               }
               |> TPC.insert()
               |> IO.inspect(label: "sx1 TPC insert result"),
             {:ok, pool} <-
               %Pool{}
               |> PoolContext.insert(
                 params
                 |> Map.merge(%{token_pair: token_pair})
               )
               |> IO.inspect(label: "sx1 PC insert") do
          {:ok, pool}
        end

      %TokenPair{id: token_pair_id} = token_pair ->
        with {:ok, %TokenPair{} = updated_token_pair} <-
               token_pair
               |> TPC.update(%{
                 status: "active",
                 decimals_adjuster_0_1: calculate_decimals_adjuster_0_1(token_pair)
               })
               |> IO.inspect(label: "sx1 TPC.update"),
             result_pool <-
               PS.with_token_pair_address_id(token_pair_address_id)
               |> PS.with_token_pair_id(token_pair_id)
               |> PS.with_dex_id(dex_v3_id)
               |> Repo.one()
               |> IO.inspect(label: "sx1 PS search") do
          case result_pool do
            nil ->
              PC.insert(
                params
                |> Map.merge(%{
                  token_pair: token_pair,
                  dex: dex,
                  token_pair_address: token_pair_address
                })
              )
              |> IO.inspect(label: "sx1 PC.insert")

            %Pool{} = pool ->
              {:ok, pool}
              |> IO.inspect(label: "sx1 pool passed over")
          end
        end
    end
  end

  # def maybe_add_token_pair_dex(
  #       %Token{id: token0_id} = token0,
  #       %Token{id: token1_id} = token1,
  #       %Dex{} = dex
  #     ) do
  #   case TPS.with_token0_id(token0_id)
  #        |> TPS.with_token1_id(token1_id)
  #        |> Repo.one() do
  #     nil ->
  #       with {:ok, token_pair} <-
  #              %{
  #                token0_id: token0_id,
  #                token1_id: token1_id,
  #                dexs: [dex],
  #                status: "inactive",
  #                decimals_adjsuter_0_1: calculate_decimals_adjuster_0_1(token0, token1)
  #              }
  #              |> TPC.insert() do
  #         {:ok, token_pair}
  #       end

  #     %TokenPair{} = token_pair ->
  #       with {:ok, updated_token_pair} <-
  #              token_pair
  #              |> TPC.update(%{
  #                dexs: [dex],
  #                status: "active",
  #                decimals_adjuster_0_1: calculate_decimals_adjuster_0_1(token_pair)
  #              }) do
  #         {:ok, updated_token_pair}
  #       end
  #   end
  # end
end
