defmodule StateGenServer do
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
    :timer.sleep(60000)
    IO.puts("sx1 in :refresh")
    # LogWritter.ipt("sx1 in :refresh")

    refreshed_state =
      with should_refresh? <- ConCache.get(:tokens, "should_refresh?"),
      new_tokens <- ConCache.get(:tokens, "new_tokens"),
           refresh_result <- refresh_tokens(should_refresh?, new_tokens, state) do
        case refresh_result do
          {:ok, updated_state} ->
            updated_state

          _ ->
            state
        end
      else
        _ -> state
      end

    GenServer.cast(__MODULE__, :refresh)

    {:noreply, refreshed_state}
  end

  defp refresh_tokens(false, _new_tokens, _state), do: IO.puts("sx1 state reconstruction not finished")
  defp refresh_tokens(_should_refresh?, nil, _state), do: IO.puts("sx1 new tokens not yet initialised")
  # defp refresh_tokens(_should_refresh?, new_tokens, _state) when Enum.count(Map.keys(new_tokens)) == 0,  do: IO.puts("sx1 no new tokens to be added")

  defp refresh_tokens(true, new_tokens, state) do
    LogWritter.ipt("sx1 state reconstruction started")

    # with new_tokens <- ConCache.get(:tokens, "new_tokens") do
      spawn(fn ->
        case Enum.count(Map.keys(new_tokens)) == 0 do
          true ->
            IO.puts("sx1 no new tokens to be added")

          false ->
            IO.puts("sx1 State Gen Server: in new tokens ")

            {:ok, state} = StateConstructor.run(1)

            # :init.restart
        end
      end)
    # end
  end
end
