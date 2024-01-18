# This file is responsible for configuring your umbrella
# and **all applications** and their dependencies with the
# help of the Config module.
#
# Note that all applications in your umbrella share the
# same configuration and dependencies, which is why they
# all use the same configuration file. If you want different
# configurations or dependencies per app, it is best to
# move said applications out of the umbrella.
import Config

# Sample configuration:
#
#     config :logger, :console,
#       level: :info,
#       format: "$date $time [$level] $metadata$message\n",
#       metadata: [:user_id]
#

config :ethers,
  rpc_client: Ethereumex.HttpClient, # Defaults to: Ethereumex.HttpClient
  keccak_module: ExKeccak, # Defaults to: ExKeccak
  json_module: Jason, # Defaults to: Jason
  secp256k1_module: ExSecp256k1, # Defaults to: ExSecp256k1
  default_signer: nil, # Defaults to: nil, see Ethers.Signer for more info
  default_signer_opts: [] # Defaults to: []

# If using Ethereumex, you can specify a default JSON-RPC server url here for all requests.
# config :ethereumex, url: "http://localhost:8545"
config :ethereumex, url: "https://eth-mainnet.g.alchemy.com/v2/#{System.get_env("ALCHEMY_API_KEY")}"
