defmodule DexBot do
  @moduledoc """
  Documentation for `ArbitrageBotV1`.
  """

  @doc """
  """

  import Compute

  use GenServer

  @dexs Libraries.dexs()
  @tokens Libraries.tokens()

  def start_link(params) do
    IO.puts("start_link(params)")
    GenServer.start_link(__MODULE__, params, name: __MODULE__)
  end

  def init(state_init) do
    state_init
    |> IO.inspect(label: "sx1 state_init")

    with true <- state_init != [] do
      IO.puts("init(state_init)")
      state =
        :persistent_term.get(
          :dexbot_state,
          state_init
        )

      {:ok, state}
      else
        _ ->
          state = state_init ++ InitialiseDexBot.run(state_init)
          :persistent_term.put(:dexbot_state, state)

          {:ok, state}
    end

  end

  def handle_call(:state, _from, state) do
    {:reply, state, state}
  end

  def handle_call(:persistent, _from, state) do
    result =
      :persistent_term.get(:dexbot_state, state)

    {:reply, result, state}
  end

  ##TODO Not priority but need to ensure what is added is a Dex Struct type of data
  def handle_cast({:add_dex, list_dex}, state) when is_list(list_dex) do
    {:noreply, state ++ list_dex}
  end

  def handle_cast({:swap_detected, event}, state) do
    state
    |> CheckProfit.run(event)

    {:noreply, state}
  end

  def handle_info(:stop, state) do
    raise "Stopped"

    {:noreply, state}
  end

  def terminate(_reason, state) do
    :persistent_term.put(:dexbot_state, state)
  end


end
