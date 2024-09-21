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
      "weth" => %{
        "name" => "weth",
        "symbol" => "WETH",
        "address" => "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2",
        "decimals" => 18
      },
      "shib" => %{
        "name" => "shib",
        "symbol" => "SHIB",
        "address" => "0x95aD61b0a150d79219dCF64E1E6Cc01f0B64C4cE",
        "decimals" => 18
      },
      "usdc" => %{
        "name" => "usdc",
        "symbol" => "USDC",
        "address" => "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48",
        "decimals" => 6
      },
      "dai" => %{
        "name" => "Dai Stablecoin",
        "symbol" => "DAI",
        "address" => "0x6B175474E89094C44Da98b954EedeAC495271d0F",
        "decimals" => 18
      },
      "usdt" => %{
        "name" => "Tether USD",
        "symbol" => "USDT",
        "address" => "0xdAC17F958D2ee523a2206206994597C13D831ec7",
        "decimals" => 6
      },
      "pepe" => %{
        "name" => "Pepe",
        "symbol" => "PEPE",
        "address" => "0x6982508145454Ce325dDbE47a25d4ec3d2311933",
        "decimals" => 18
      },
      "mkr" => %{
        "name" => "Maker",
        "symbol" => "MKR",
        "address" => "0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2",
        "decimals" => 18
      },
      "wise" => %{
        "name" => "Wise Token",
        "symbol" => "WISE",
        "address" => "0x66a0f676479Cee1d7373f3DC2e2952778BfF5bd6",
        "decimals" => 18
      }
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
