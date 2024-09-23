defmodule LogsWritter do
  use GenServer

  # Client API

  def start_link([]) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def save_logs do
    GenServer.cast(__MODULE__, :save_logs)
  end

  # GenServer callbacks

  def init([]) do
    GenServer.cast(__MODULE__, :save_logs)

    {:ok, []}
  end

  def handle_cast(:save_logs, state) do
    #TODO open a file with the name being today's data
    #TODO write the content of the logs concache at the end of the file (append)
    #TODO then reset state of concache logs
    #TODO recall LogsWritter after 1min

    # gas_result = EtherscanGasTrackerApi.get_gas_oracle()

    # case gas_result do
    #   %{
    #     "result" => %{
    #       "FastGasPrice" => fast_gas_price_raw,
    #       "LastBlock" => last_block
    #     }
    #   } ->
    #     max_gas_limit =
    #       convert_string_to_value(System.get_env("GAS_LIMIT"))

    #     fast_gas_price =
    #       convert_string_to_value(fast_gas_price_raw)

    #     estimated_gas_fee = fast_gas_price * max_gas_limit / 1_000_000_000

    #     ConCache.put(:gas, :fast_gas_price, fast_gas_price)
    #     ConCache.put(:gas, :last_block, last_block)
    #     ConCache.put(:gas, :estimated_gas_fee, estimated_gas_fee)

    #   {:error, reason} ->
    #     %{"error" => reason} |> IO.inspect(label: "sx1 gas_extract error result")
    # end

    # :timer.sleep(1000)
    # GenServer.cast(__MODULE__, :save_logs)

    {:noreply, state}
  end

  # def convert_string_to_value(number) when is_binary(number) do
  #   with number_list <- String.split(number, "."),
  #        true <- is_number_list_an_integer?(number_list) do
  #     number |> String.to_integer()
  #   else
  #     _ ->
  #       number |> String.to_float()
  #   end
  # end

  # def is_number_list_an_integer?(number_list) do
  #   length(number_list) == 1
  # end
end
