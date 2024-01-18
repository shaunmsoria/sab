defmodule DexBot do
  # use Ethers.Contract,
  # abi_file: System.get_env("ABI_UNISWAP"),
  # default_address: Jason.decode!(System.get_env("UNISWAP"), as: %{}) |> Map.get("FACTORY_ADDRESS")

  alias Ethers.Contract

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
    |> IO.inspect(label: "sx1 ALCHEMY_API_KEY")

    Jason.decode!(System.get_env("UNISWAP"), as: %{}) |> Map.get("FACTORY_ADDRESS")
    |> IO.inspect(label: "sx1 FACTORY_ADDRESS")

    System.get_env("ABI_UNISWAP")
    |> IO.inspect(label: "sx1 ABI_UNISWAP")


    :world
  end
end
