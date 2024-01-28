defmodule DexBotTest do
  use ExUnit.Case
  doctest DexBot

  test "greets the world" do
    assert DexBot.run() == {:ok, :done}
    assert DexBot.start_link() == {:ok, :start_link}
  end
end
