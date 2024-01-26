defmodule Libraries do


  def dexs() do %{
      uniswap: %{
        v2_router_02_address: "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D",
        factory_address: "0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f"
        },
      sushiswap: %{
        v2_router_02_address: "0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F",
        factory_address: "0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac"
      }
    }
  end

  def tokens() do
    %{
      weth: %{
        name: "WETH",
        address: "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2"
      },
      shib: %{
        name: "SHIB",
        address: "0x95aD61b0a150d79219dCF64E1E6Cc01f0B64C4cE"
      }
    }
  end

end
