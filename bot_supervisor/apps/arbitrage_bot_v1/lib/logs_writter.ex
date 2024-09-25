defmodule LogsWritter do
  use GenServer

  # Client API

  def start_link(%{}) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def save_logs do
    GenServer.cast(__MODULE__, :save_logs)
  end

  # GenServer callbacks

  def init(%{}) do
    GenServer.cast(__MODULE__, :save_logs)

    {:ok, %{}}
  end

  def handle_cast(:save_logs, state) do
    # TODO open a file with the name being today's data
    # TODO write the content of the logs concache at the end of the file (append)
    # TODO then reset state of concache logs
    # TODO recall LogsWritter after 1min

    IO.puts("sx1 in save_logs")

    # ConCache.put(:logs, :console, "test\n")

    message = ConCache.get(:logs, :console)
    |> IO.inspect(label: "sx1 logs console before the concache get")

    date = Date.utc_today()

    file_name = "console_#{date.day}_#{date.month}_#{date.year}.log"

    File.write("/home/shaun/Programs/sab/bot_supervisor/log/#{file_name}", message, [:append])



    :timer.sleep(1000)

    ConCache.put(:logs, :console, "")


    GenServer.cast(__MODULE__, :save_logs)

    {:noreply, state}
  end
end
