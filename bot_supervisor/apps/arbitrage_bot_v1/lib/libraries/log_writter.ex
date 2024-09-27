defmodule LogWritter do
  alias LogSaver, as: LS


  ## TODO finish function to do the IO.inspect and save element in ConCache with label message

  def ipt(element, message \\ "") when is_binary(message) do
    with element_formatted <- element |> inspect(),
         current_log <- ConCache.get(:logs, :console) do
      ConCache.put(:logs, :console, element_formatted)

      case message do
        "" ->
          element |> IO.inspect()

        _ ->
          element
          |> IO.inspect(label: message)
      end
    else
      error -> LS.write_log(error)
    end
  end
end
