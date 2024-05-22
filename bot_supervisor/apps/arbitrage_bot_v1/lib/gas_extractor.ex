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
      %{
        "result" =>
        %{
          "FastGasPrice" => fast_gas_price_raw,
          "LastBlock" => last_block
          }
        } ->

          max_gas_limit =
            System.get_env("GAS_LIMIT")
            |> String.to_integer()

          fast_gas_price =
            fast_gas_price_raw
            |> String.to_integer()

          estimated_gas_fee = fast_gas_price * max_gas_limit / 1000000000


          ConCache.put(:gas, :fast_gas_price, fast_gas_price)
          ConCache.put(:gas, :last_block, last_block)
          ConCache.put(:gas, :estimated_gas_fee, estimated_gas_fee)


          {:error, reason} -> %{"error" => reason} |> IO.inspect(label: "sx1 gas_extract error result")
    end

    :timer.sleep(1000)
    GenServer.cast(__MODULE__, :refresh)

    {:noreply, state}
  end
end
