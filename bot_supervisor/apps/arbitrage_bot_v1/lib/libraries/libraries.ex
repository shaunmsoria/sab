defmodule Libraries do
  # defmodule DexPair do
  #   defstruct dex0: %{}, dex1: %{}, pairs: %{}
  # end

  def dexs() do
    %{
      uniswap: %Dex{
        name: "uniswap",
        version: "2",
        router: "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D",
        factory: "0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f",
        subgraph_url: "https://gateway-arbitrum.network.thegraph.com/api",
        subgraph_api_key: "17c4cccfd28795b7a90b4a815fab12cc",
        subgraph_id: "A3Np3RQbaBA6oKJgiwDJeo5T3zrYfGHPWFYayMwtNDum",
        subgraph_query: "{pairs {id token0 {id symbol} token1 {id symbol}}}"
      },
      sushiswap: %Dex{
        name: "sushiswap",
        version: "2",
        router: "0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F",
        factory: "0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac",
        subgraph_url: "https://gateway-arbitrum.network.thegraph.com/api",
        subgraph_api_key: "17c4cccfd28795b7a90b4a815fab12cc",
        subgraph_id:  "9tHceukBZ5hFEcAH7zoV5zXxGDYQRezZr1ZMgwUcLK5w",
        subgraph_query: "{pools {id token0 {id symbol} token1 {id symbol}}}"
      }
    }
  end

  def tokens() do
    %{
      weth: %Token{
        name: "weth",
        symbol: "WETH",
        address: "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2"
      },
      shib: %Token{
        name: "shib",
        symbol: "SHIB",
        address: "0x95aD61b0a150d79219dCF64E1E6Cc01f0B64C4cE"
      }
    }
  end
end
