defmodule DexBot do
  @moduledoc """
  Documentation for `ArbitrageBotV1`.
  """

  @doc """
  Hello world.

  ## Examples

      iex> ArbitrageBotV1.hello()
      :world

  """
  def hello do
    IO.puts("hello world DexBot")

    System.get_env("ALCHEMY_API_KEY")
    |> IO.inspect(label: "mx1 ALCHEMY_API_KEY")

    :world
  end
end
