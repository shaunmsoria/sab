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


  # import UniswapSmartContract

  @dexs Libraries.dexs
  @tokens Libraries.tokens


  def run do


    System.get_env("ALCHEMY_API_KEY")
    |> IO.inspect(label: "sx1 ALCHEMY_API_KEY")

    @dexs.uniswap.factory_address
    |> IO.inspect(label: "sx1 FACTORY_ADDRESS")

    @dexs.uniswap.v2_router_02_address
    |> IO.inspect(label: "sx1 V2_ROUTER_02_ADDRESS")

    {:ok, pair_address} = Compute.get_pair_address(
      @dexs.uniswap.factory_address,
      @tokens.weth.address,
      @tokens.shib.address
    )

    pair_address
    |> IO.inspect(label: "sx1 get_pair_address")

    # pair_address
    # |> pair_contract()





    :world
  end

  def pair_contract() do

  end

end
