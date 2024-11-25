import Seedex

seed_once(Dex, [
  %{
    name: "uniswap",
    version: 2,
    router: "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D",
    factory: "0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f"
  },
  %{
    name: "sushiswap",
    version: 2,
    router: "0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F",
    factory: "0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac"
  },
  %{
    name: "pancakeswap",
    version: 2,
    router: "0xEfF92A263d31888d860bD50809A8D171709b7b1c",
    factory: "0x1097053Fd2ea711dad45caCcc45EfF7548fCB362"
  }
])
