defmodule DexBotTest do
  use ExUnit.Case
  doctest DexBot

  test "greets the world" do

    assert DexBot.run() == {:ok, :done}

    assert %DexPair{
      dex0: :uniswap,
      dex1: :sushiswap
      } = GenServer.call(DexBot, :state_value)
      # |> IO.inspect(label: "sx1 GenServer.call result")
  end
end
