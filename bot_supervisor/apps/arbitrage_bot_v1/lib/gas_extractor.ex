defmodule GasExtractor do
  use GenServer

  # Client API

  def start_link(%{}) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def refresh do
    GenServer.cast(__MODULE__, :refresh)
  end

  # GenServer callbacks

  def init(%{}) do

    GenServer.cast(__MODULE__, :refresh)

    {:ok, %{}}
  end

  def handle_cast(:refresh, state) do
    gas_result = EtherscanGasTrackerApi.get_gas_oracle()

    case gas_result do
      %{"result" =>
        %{"FastGasPrice" => fast_gas_price,
        "LastBlock" => last_block}} ->
          ConCache.put(:gas, :fast_gas_price, fast_gas_price)
          ConCache.put(:gas, :last_block, last_block)

          ConCache.get(:gas, :fast_gas_price) |> IO.inspect(label: "sx1 fast_gas_price")
          ConCache.get(:gas, :last_block) |> IO.inspect(label: "sx1 last_block")



    end



    :timer.sleep(1000)
    GenServer.cast(__MODULE__, :refresh)

    {:noreply, state}
  end

  # def handle_call(:decrement, _from, state) do
  #   {:reply, state - 1, state - 1}
  # end
end
