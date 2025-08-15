defmodule Sabv2Contract do
  use Ethers.Contract,
    abi_file: "/home/server/Programs/sab/v2_smart_contract/artifacts/contracts/SABV2.sol/SABV2.json"

  # abi_file: "/home/server/Programs/sab/bot_supervisor/apps/arbitrage_bot_v1/lib/libraries/json/sabv4_abi.json"
  # abi_file: "/home/server/Programs/sab/bot_supervisor/apps/arbitrage_bot_v1/lib/libraries/json/sabv2_abi.json"
end
