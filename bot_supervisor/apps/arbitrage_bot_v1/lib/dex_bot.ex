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
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
    {:ok, :start_link}
  end

  def init(state) do
    {:ok, state}
  end


  def handle_call(:hello_world, _from, state) do
    IO.puts("mx1 hello world")

    state |> IO.inspect(label: "sx1 state")
    {:reply, "Hello World", state}
  end

  def handle_info({:add_value, %{} = value}, state) do

    new_state =
      Map.merger(state, value)

    {:noreply, new_state}
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
