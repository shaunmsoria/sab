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
        "result" => %{
          "FastGasPrice" => fast_gas_price_raw,
          "LastBlock" => last_block
        }
      } ->
        max_gas_limit =
          convert_string_to_value(System.get_env("GAS_LIMIT"))

        # max_gas_limit =
        #   System.get_env("GAS_LIMIT")
        #   |> String.to_float()

        fast_gas_price =
          convert_string_to_value(fast_gas_price_raw)

        # fast_gas_price =
        #   fast_gas_price_raw
        #   |> String.to_float()

        estimated_gas_fee = fast_gas_price * max_gas_limit / 1_000_000_000

        ConCache.put(:gas, :fast_gas_price, fast_gas_price)
        ConCache.put(:gas, :last_block, last_block)
        ConCache.put(:gas, :estimated_gas_fee, estimated_gas_fee)

      {:error, reason} ->
        %{"error" => reason} |> IO.inspect(label: "sx1 gas_extract error result")
    end

    :timer.sleep(1000)
    GenServer.cast(__MODULE__, :refresh)

    {:noreply, state}
  end

  def convert_string_to_value(number) when is_binary(number) do
    with number_list <- String.split(number, "."),
         true <- is_number_list_an_integer?(number_list) do
      number |> String.to_integer()
    else
      _ ->
        number |> String.to_float()
    end
  end

  def is_number_list_an_integer?(number_list) do
    length(number_list) == 1
  end
end
