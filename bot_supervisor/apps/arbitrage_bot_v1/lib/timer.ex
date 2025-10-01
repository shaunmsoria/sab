defmodule Timer do
  use GenServer
  import Ecto.Query

  # Client API

  def start_link(%{}) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def refresh_gas, do: GenServer.cast(__MODULE__, :refresh_gas)

  def refresh_reserve, do: GenServer.cast(__MODULE__, :refresh_reserve)

  # GenServer callbacks

  def init(%{}) do
    GenServer.cast(__MODULE__, :refresh_gas)
    GenServer.cast(__MODULE__, :refresh_reserve)

    {:ok, %{}}
  end

  def handle_cast(:refresh_gas, state) do
    gas_result = EtherscanApi.get_gas_oracle()
    |> IO.inspect(label: "sx1 gas_result")

    case gas_result do
      %{
        "result" => %{
          "FastGasPrice" => fast_gas_price_raw,
          "LastBlock" => last_block
        }
      } ->
        max_gas_limit =
          convert_string_to_value(System.get_env("GAS_LIMIT"))

        fast_gas_price =
          convert_string_to_value(fast_gas_price_raw) * 1.0e9

        max_priority_fee_per_gas = round(fast_gas_price * 2)
        max_fee_per_gas = round(fast_gas_price * 3)

        # max_priority_fee_per_gas = round(fast_gas_price * 1.2)
        # max_fee_per_gas = round(fast_gas_price * 2)

        estimated_aggressive_max_gas_fee = max_fee_per_gas * max_gas_limit

        ConCache.put(:gas, :max_priority_fee_per_gas, max_priority_fee_per_gas)
        ConCache.put(:gas, :max_fee_per_gas, max_fee_per_gas)
        ConCache.put(:gas, :gas_limit, convert_string_to_value(System.get_env("GAS_LIMIT")))
        ConCache.put(:gas, :estimated_aggressive_max_gas_fee, estimated_aggressive_max_gas_fee)

      {:error, reason} ->
        %{"error" => reason} |> LogWritter.ipt("sx1 gas_extract error result")
    end

    :timer.sleep(10000)
    GenServer.cast(__MODULE__, :refresh_gas)

    {:noreply, state}
  end

  @doc """
  :refresh_reserve -> reset refresh_reserve to true after specified time
  """
  def handle_cast(:refresh_reserve, state) do
    :timer.sleep(10_800_000)

    Repo.update_all(Pool, set: [refresh_reserve: true])

    GenServer.cast(__MODULE__, :refresh_reserve)

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
