defmodule LogSaver do
  use GenServer

  # Client API

  def start_link(params) do
    GenServer.start_link(__MODULE__, params, name: __MODULE__)
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
    # ? can change the DateTime.now!("Etc/UTC") to Melbourne time

    # IO.puts("sx1 in save_logs")

    write_log()

    :timer.sleep(1000)

    GenServer.cast(__MODULE__, :save_logs)

    {:noreply, state}
  end

  def write_log() do
    with true <- not is_nil(ConCache.get(:logs, :console)),
         {file_name, message} <- file_log(ConCache.get(:logs, :console)),
         :ok <-
           File.write(
             "/home/server/Programs/sab/bot_supervisor/apps/arbitrage_bot_v1/lib/log/#{file_name}",
             message,
             [:append]
           ) do
      ConCache.put(:logs, :console, nil)
    else
      _ -> nil
    end
  end

  def write_log(message_raw) do
    with message_formatted <- message_raw |> inspect(),
         {file_name, message} <- file_log(message_formatted) do
      File.write(
        "/home/server/Programs/sab/bot_supervisor/apps/arbitrage_bot_v1/lib/log/#{file_name}",
        message,
        [:append]
      )
    else
      error -> write_log(error)
    end
  end

  defp file_log(message_raw) when is_binary(message_raw) do
    with date <- DateTime.now!("Etc/UTC"),
         file_name <- "console_#{date.day}_#{date.month}_#{date.year}.log",
         message <-
           "Time: #{date.hour}:#{date.minute}:#{date.second}  " <>
             message_raw <> "\n\n" do
      {file_name, message}
    end
  end
end
