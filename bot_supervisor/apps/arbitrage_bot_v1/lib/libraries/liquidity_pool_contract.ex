defmodule LiquidityPoolContract do
  use Ethers.Contract,
    abi_file:
      "/home/shaun/Programs/sab/bot_supervisor/apps/arbitrage_bot_v1/lib/libraries/json/liquidity_pool_abi_v2.json"
end
