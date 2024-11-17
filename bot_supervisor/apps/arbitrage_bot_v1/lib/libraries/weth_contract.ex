defmodule WethContract do
  use Ethers.Contract,
    abi_file:
      "/home/server/Programs/sab/bot_supervisor/apps/arbitrage_bot_v1/lib/libraries/json/weth_abi.json"
end
