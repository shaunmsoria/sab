defmodule DexBot.Handler do
  use W3WS.Handler
  use GenServer

  @impl W3WS.Handler
  def handle_event(
        %Env{
            decoded?: true,
            event: %Event{name: "Swap", data: _data}
            # event: %Event{name: "Swap", data: %{"from" => from}}
        } = event,
        _state
    ) do

      GenServer.cast(DexBot, {:swap_detected, event})
      # data
      # |> IO.inspect(label: "sx1 from data")
    # Logger.debug("received Swap event from #{from}")
  end
end
