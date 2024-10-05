defmodule LogWritter do
  def ipt(element, message \\ "") when is_binary(message) do
    with element_formatted <- element |> inspect(),
         log_formatted <- message <> ":" <> "\n" <> element_formatted,
         current_log <- ConCache.get(:logs, :console) do
      case current_log do
        nil ->
          ConCache.put(:logs, :console, log_formatted)

        current_log ->
          ConCache.put(:logs, :console, current_log <> "\n" <> log_formatted)
      end

      case message do
        "" ->
          element |> IO.inspect()

        _ ->
          element
          |> IO.inspect(label: message)
      end
    else
      error -> LogSaver.write_log(error)
    end
  end
end
