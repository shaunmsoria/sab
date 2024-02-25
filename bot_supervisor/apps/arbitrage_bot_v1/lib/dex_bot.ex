defmodule DexBot do
  @moduledoc """
  Documentation for `ArbitrageBotV1`.
  """

  @doc """
  Hello world.

  ## Examples

      iex> ArbitrageBotV1.hello()
      :world

  """

  import Compute

  use GenServer

  @dexs Libraries.dexs()
  @tokens Libraries.tokens()

  def start_link(params) do
    GenServer.start_link(__MODULE__, params, name: __MODULE__)
  end

  def init(state_init) do
    state =
      :persistent_term.get(
        :dexbot_state,
        state_init
      )

    {:ok, pair_address_uni} =
      Compute.get_pair_address(
        @dexs.uniswap.factory,
        @tokens.weth.address,
        @tokens.shib.address
      )

    {:ok, state}
  end

  def handle_call(:state, _from, state) do
    {:reply, state, state}
  end

  def handle_call(:persistent, _from, state) do
    result =
      :persistent_term.get(
        :dexbot_state,
        state
      )

    {:reply, result, state}
  end

  def handle_cast({:add_pair, value}, state) when is_list(value) do
    {:noreply, %{state | pairs: state.pairs ++ value}}
  end

  def handle_cast({:swap_detected, event}, state) do
    event
    |> CheckProfit.run()

    {:noreply, state}
  end

  def handle_info(:stop, state) do
    raise "Stopped"

    {:noreply, state}
  end

  # def handle_info(:terminate, state) do
  #   IO.puts("sx1 handle_info triggered")

  #     :persistent_term.put(
  #       :dexbot_state,
  #       state
  #       )

  #       {:noreply, state}
  # end

  def terminate(_reason, state) do
    :persistent_term.put(
      :dexbot_state,
      state
    )
  end

  def run do
    System.get_env("ALCHEMY_API_KEY")
    |> IO.inspect(label: "sx1 ALCHEMY_API_KEY")

    @dexs.uniswap.factory
    |> IO.inspect(label: "sx1 FACTORY_ADDRESS")

    @dexs.uniswap.router
    |> IO.inspect(label: "sx1 V2_ROUTER_02_ADDRESS")

    {:ok, pair_address_uni} =
      Compute.get_pair_address(
        @dexs.uniswap.factory,
        @tokens.weth.address,
        @tokens.shib.address
      )

    {:ok, pair_address_sushi} =
      Compute.get_pair_address(
        @dexs.sushiswap.factory,
        @tokens.weth.address,
        @tokens.shib.address
      )

    pair_address_uni
    |> contract(:get_reserves)
    |> IO.inspect(label: "sx1 pair_address_uni |> contract(:get_reserves)")

    price_0 =
      pair_address_uni
      |> calculate_price()
      |> IO.inspect(label: "sx1 price_0")

    pair_address_sushi
    |> contract(:get_reserves)
    |> IO.inspect(label: "sx1 pair_address_sushi |> contract(:get_reserves)")

    price_1 =
      pair_address_sushi
      |> calculate_price()
      |> IO.inspect(label: "sx1 price_1")

    calculate_difference(price_0, price_1)
    |> IO.inspect(label: "sx1 calculate_difference")

    {:ok, result} =
      Compute.get_all_pairs(@dexs.uniswap.factory, 0)
      |> IO.inspect(label: "sx Compute.get_all_pairs")

    {:ok, :done}
  end
end

## references:

# LiquidityPoolContract.EventFilters.swap(pair_address_uni, nil)
# |> Ethers.get_logs()
# |> IO.inspect(label: "sx1 EventFilters")

# pair_address_uni |> contract_logs(:swap)
# |> IO.inspect(label: "sx1 pair_address_uni |> contract(:swap)")
