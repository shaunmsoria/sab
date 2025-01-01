import Seedex

seed_once(Dex, [
  # %{
  #   name: "uniswap",
  #   router: "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D",
  #   factory: "0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f",
  #   abi: "uniswapV2"
  # },
  # %{
  #   name: "sushiswap",
  #   router: "0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F",
  #   factory: "0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac",
  #   abi: "uniswapV3"
  # },
  # %{
  #   name: "pancakeswap",
  #   router: "0xEfF92A263d31888d860bD50809A8D171709b7b1c",
  #   factory: "0x1097053Fd2ea711dad45caCcc45EfF7548fCB362",
  #   abi: "uniswapV2"
  # },
  %{
    name: "uniswap",
    router: "0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45",
    factory: "0x1F98431c8aD98523631AE4a59f267346ea31F984",
    quoter: "0x61fFE014bA17989E743c5F6cB21bF9697530B21e",
    abi: "uniswapV3"
  },
  %{
    name: "sushiswap",
    router: "0x2E6cd2d30aa43f40aa81619ff4b6E0a41479B13F",
    factory: "0xbACEB8eC6b9355Dfc0269C18bac9d6E2Bdc29C4F",
    quoter: "0x64e8802FE490fa7cc61d3463958199161Bb608A7",
    abi: "uniswapV3"
  },
  %{
    name: "pancakeswap",
    router: "0x1b81D678ffb9C0263b24A97847620C99d213eB14",
    factory: "0x0BFbCF9fa4f9C56B0F40a671Ad40E0805A091865",
    quoter: "0xB048Bbc1Ee6b733FFfCFb9e9CeF7375518e25997",
    abi: "uniswapV3"
  }
])
