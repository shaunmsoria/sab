defmodule DexBot do
  # use Ethers.Contract,
  # abi_file: "/home/shaun/volume/sab/bot_supervisor/apps/arbitrage_bot_v1/lib/uniswap_abi.json"


  # abi_file: System.get_env("ABI_UNISWAP"),
  # default_address: Jason.decode!(System.get_env("UNISWAP"), as: %{}) |> Map.get("FACTORY_ADDRESS")

  import UniswapSmartContract

  # alias Ethers.Contract

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

    uniswap_factory_address =
    Jason.decode!(System.get_env("UNISWAP"), as: %{}) |> Map.get("FACTORY_ADDRESS")
    |> IO.inspect(label: "sx1 FACTORY_ADDRESS")

    uniswap_router_address =
    Jason.decode!(System.get_env("UNISWAP"), as: %{}) |> Map.get("V2_ROUTER_02_ADDRESS")
    |> IO.inspect(label: "sx1 V2_ROUTER_02_ADDRESS")


    # Ethers.Contract.ERC20.
    data  =
    UniswapSmartContract.get_pair("0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2", "0x95aD61b0a150d79219dCF64E1E6Cc01f0B64C4cE")
    |> IO.inspect(label: "sx1 getPair")

    Ethers.call(data, to: uniswap_factory_address)
    |> IO.inspect(label: "sx1 call")

    :world
  end
end
