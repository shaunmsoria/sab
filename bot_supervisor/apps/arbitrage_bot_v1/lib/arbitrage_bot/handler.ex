defmodule DexBot.Handler do
  use W3WS.Handler

  @impl W3WS.Handler
  def handle_event(
        %Env{
            decoded?: true,
            event: %Event{name: "Swap", data: %{"from" => from}}
        },
        _state
    ) do
    Logger.debug("received Swap event from #{from}")
  end
end
