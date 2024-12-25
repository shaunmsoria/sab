defmodule Libraries do

  #TODO find the balancer router address
  def dexs() do
    %{
      "uniswap" => %{
        "name" => "uniswap",
        "version" => "2",
        "router" => "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D",
        "factory" => "0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f",
        "subgraph_url" => "https://gateway-arbitrum.network.thegraph.com/api",
        "subgraph_api_key" => "17c4cccfd28795b7a90b4a815fab12cc",
        "subgraph_id" => "A3Np3RQbaBA6oKJgiwDJeo5T3zrYfGHPWFYayMwtNDum",
        "subgraph_query" => "{pairs {id token0 {id symbol} token1 {id symbol}}}"
      },
      "sushiswap" => %{
        "name" => "sushiswap",
        "version" => "2",
        "router" => "0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F",
        "factory" => "0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac",
        "subgraph_url" => "https://gateway-arbitrum.network.thegraph.com/api",
        "subgraph_api_key" => "17c4cccfd28795b7a90b4a815fab12cc",
        "subgraph_id" => "9tHceukBZ5hFEcAH7zoV5zXxGDYQRezZr1ZMgwUcLK5w",
        "subgraph_query" => "{pools {id token0 {id symbol} token1 {id symbol}}}"
      },
      "pancakeswap" => %{
        "name" => "pancakeswap",
        "version" => "2",
        "router" => "0xEfF92A263d31888d860bD50809A8D171709b7b1c",
        "factory" => "0x1097053Fd2ea711dad45caCcc45EfF7548fCB362",
        "subgraph_url" => "",
        "subgraph_api_key" => "",
        "subgraph_id" => "",
        "subgraph_query" => ""
      }
    }
  end

  def tokens() do
    %{
      "0XC02AAA39B223FE8D0A0E5C4F27EAD9083C756CC2" => %{
        "name" => "weth",
        "symbol" => "WETH",
        "address" => "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2",
        "decimals" => 18
      },
      "0X95AD61B0A150D79219DCF64E1E6CC01F0B64C4CE" => %{
        "name" => "shib",
        "symbol" => "SHIB",
        "address" => "0x95aD61b0a150d79219dCF64E1E6Cc01f0B64C4cE",
        "decimals" => 18
      },
      "0XA0B86991C6218B36C1D19D4A2E9EB0CE3606EB48" => %{
        "name" => "usdc",
        "symbol" => "USDC",
        "address" => "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48",
        "decimals" => 6
      },
      # "0x6B175474E89094C44Da98b954EedeAC495271d0F" => %{
      #   "name" => "Dai Stablecoin",:w

      #   "symbol" => "DAI",
      #   "address" => "0x6B175474E89094C44Da98b954EedeAC495271d0F",
      #   "decimals" => 18
      # },
      # "0X6B175474E89094C44DA98B954EEDEAC495271D0F" => %{
      #   "name" => "Tether USD",
      #   "symbol" => "USDT",
      #   "address" => "0xdAC17F958D2ee523a2206206994597C13D831ec7",
      #   "decimals" => 6
      # },
      # "0X6982508145454CE325DDBE47A25D4EC3D2311933" => %{
      #   "name" => "Pepe",
      #   "symbol" => "PEPE",
      #   "address" => "0x6982508145454Ce325dDbE47a25d4ec3d2311933",
      #   "decimals" => 18
      # },
      # "0X9F8F72AA9304C8B593D555F12EF6589CC3A579A2" => %{
      #   "name" => "Maker",
      #   "symbol" => "MKR",
      #   "address" => "0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2",
      #   "decimals" => 18
      # },
      # "0X66A0F676479CEE1D7373F3DC2E2952778BFF5BD6" => %{
      #   "name" => "Wise Token",
      #   "symbol" => "WISE",
      #   "address" => "0x66a0f676479Cee1d7373f3DC2e2952778BfF5bd6",
      #   "decimals" => 18
      # },
      # "0XEC53BF9167F50CDEB3AE105F56099AAAB9061F83" => %{
      #   "name" => "Eigen",
      #   "symbol" => "EIGEN",
      #   "address" => "0xec53bF9167f50cDEB3Ae105f56099aaaB9061F83",
      #   "decimals" => 18
      # },
      # "0XAAEE1A9723AADB7AFA2810263653A34BA2C21C7A" => %{
      #   "name" => "Mog Coin",
      #   "symbol" => "MOG",
      #   "address" => "0xaaeE1A9723aaDB7afA2810263653A34bA2C21C7a",
      #   "decimals" => 18
      # },
    }
  end

  def balancer() do
    %{
      "pool_address" => "0x5B42eC6D40f7B7965BE5308c70e2603c0281C1E9",
      "base_url" => "https://api.thegraph.com/subgraphs/name/balancer-labs/balancer-v2/graphql?",
      "subgraph_query" =>
        "{query MyQuery {poolTokens {address token {address name symbol} id balance}}}",
      "url" =>
        "https://api.thegraph.com/subgraphs/name/balancer-labs/balancer-v2/graphql?query=query+MyQuery+%7B%0A++poolTokens+%7B%0A++++address%0A++++token+%7B%0A++++++address%0A++++++name%0A++++++symbol%0A++++%7D%0A++++id%0A++++balance%0A++%7D%0A%7D#"
    }
  end
end
