defmodule DexBotTest do
  use ExUnit.Case
  doctest DexBot

  test "greets the world" do
    assert DexBot.run() == :world
  end
end
