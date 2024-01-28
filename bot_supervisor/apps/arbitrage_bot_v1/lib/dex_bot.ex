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

  @dexs Libraries.dexs
  @tokens Libraries.tokens

  def start_link() do
    GenServer.start_link(__MODULE__, nil)
    {:ok, :start_link}
  end

  def init(_) do
    subscribe_to_block_headers()
    {:ok, %{}}
  end

  def handle_info({:ethereumex, {:subscribe, _}}, state) do
    {:ok, filter_id} = Ethereumex.Eth.filter_new_blocks(%{})
    {:noreply, Map.put(state, :filter_id, filter_id)}
  end

  def handle_info({:ethereumex, {:log, log}}, state) do
    case parse_swap_event(log) do
      {:ok, swap_event} ->
        # Process the swap event
        IO.puts("Swap event detected: #{inspect(swap_event)}")
      {:error, _} ->
        IO.puts("Error parsing swap event")
    end
    {:noreply, state}
  end

  defp subscribe_to_block_headers() do
    Ethereumex.Eth.subscribe_new_heads()
  end

  defp parse_swap_event(log) do
    # Parse the swap event from the log data
    # You'll need to implement this based on the event structure
    # emitted by the Uniswap contracts
    {:ok, :swap_event}
  end


  def run do


    System.get_env("ALCHEMY_API_KEY")
    |> IO.inspect(label: "sx1 ALCHEMY_API_KEY")

    @dexs.uniswap.factory_address
    |> IO.inspect(label: "sx1 FACTORY_ADDRESS")

    @dexs.uniswap.v2_router_02_address
    |> IO.inspect(label: "sx1 V2_ROUTER_02_ADDRESS")

    {:ok, pair_address_uni} = Compute.get_pair_address(
      @dexs.uniswap.factory_address,
      @tokens.weth.address,
      @tokens.shib.address
    )

    {:ok, pair_address_sushi} = Compute.get_pair_address(
      @dexs.sushiswap.factory_address,
      @tokens.weth.address,
      @tokens.shib.address
    )


    pair_address_uni |> contract(:get_reserves)
    |> IO.inspect(label: "sx1 pair_address_uni |> contract(:get_reserves)")

    price_0 =
    pair_address_uni
    |> calculate_price()
    |> IO.inspect(label: "sx1 price_0")


    pair_address_sushi |> contract(:get_reserves)
    |> IO.inspect(label: "sx1 pair_address_sushi |> contract(:get_reserves)")

    price_1 =
    pair_address_sushi
    |> calculate_price()
    |> IO.inspect(label: "sx1 price_1")

    calculate_difference(price_0, price_1)
    |> IO.inspect(label: "sx1 calculate_difference")




    {:ok, :done}
  end


end
