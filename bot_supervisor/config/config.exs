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

config :logger,
  backends: [{LoggerFileBackend, :info_log}]

config :logger, :info_log,
  path: "log/info.log",
  level: :error,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]


config :logger, :console,
  level: :error,
  # level: :debug,
  # level: :info,
  # level: :critical,
  format: "$date $time [$level] $metadata$message\n"






config :ethers,
  # Defaults to: Ethereumex.HttpClient
  rpc_client: Ethereumex.HttpClient,
  # Defaults to: ExKeccak
  keccak_module: ExKeccak,
  # Defaults to: Jason
  json_module: Jason,
  # Defaults to: ExSecp256k1
  secp256k1_module: ExSecp256k1,
  # Defaults to: nil, see Ethers.Signer for more info
  default_signer: Ethers.Signer.JsonRPC,
  # Defaults to: []
  default_signer_opts: []

# # If using Ethereumex, you can specify a default JSON-RPC server url here for all requests.
# # config :ethereumex, url: "http://localhost:8545"
config :ethereumex,
  # url: "http://127.0.0.1:8545"

# url: "https://eth-mainnet.g.alchemy.com/v2/#{System.get_env("ALCHEMY_API_KEY")}"
url: "https://mainnet.infura.io/v3/#{System.get_env("INFURA_API_KEY")}"
# url: "https://mainnet.infura.io/v3/#{System.get_env("INFURA_API_KEY2")}"

# in your config.exs
config :arbitrage_bot_v1, W3WS,
  listeners: [
    [
      # the uri of the ethereum jsonrpc websocket server
      # uri: "ws://127.0.0.1:8545",
      # uri: "wss://eth-mainnet.g.alchemy.com/v2/#{System.get_env("ALCHEMY_API_KEY")}",
      uri: "wss://mainnet.infura.io/ws/v3/#{System.get_env("INFURA_API_KEY")}",
      # uri: "wss://mainnet.infura.io/ws/v3/#{System.get_env("INFURA_API_KEY2")}",

      # enable block ping every 10 seconds. this will cause the listener to
      # fetch and log the current block every 10 seconds. the last fetched block
      # will be available from `Listener.get_block/1`. Defaults to `nil` which
      # disables block ping.
      block_ping: :timer.seconds(10),

      # a helper setting for dealing with finicky local nodes (ie hardhat) where the
      # server stops sending subscription events after some time. setting this to
      # a number of milliseconds will cause the listener to unsubscribe and resubscribe
      # all configured subscriptions every `resubscribe` milliseconds. Defaults to `nil`
      # which disables resubscribing.
      # https://github.com/NomicFoundation/hardhat/issues/2053
      resubscribe: :timer.minutes(5),

      # subscriptions to setup on this websocket connection. each listener
      # can support many subscriptions and will call the corresponding handler
      # for each subscription event, using the provided subscription abi, if any,
      # to decode events for the subscription.
      subscriptions: [
        [
          # one of `abi` or `abi_files` is necessary to decode events.
          # neither are required if you jsut want to listen for encoded events.
          # abi: abi,                        # decoded json abi
          # list of paths to abi json files
          abi_files: [
            "/home/shaun/Programs/sab/bot_supervisor/apps/arbitrage_bot_v1/lib/libraries/json/liquidity_pool_abi_v2.json"
          ],
          # abi_files: ["/home/shaun/volume/sab/bot_supervisor/apps/arbitrage_bot_v1/lib/libraries/json/uniswap_abi_v2.json"], # list of paths to abi json files

          # an optional `context` to provide in the `W3WS.Env` struct for any events
          # received from this subscription. Defaults to `%{}`.
          context: %{chain_id: 1},

          # handler to call for each received event. can be either a module which `use`s
          # `W3WS.Handler` and defines a `c:W3WS.Handler.handle_event/2` function, an
          # anonymous function which accepts a `%W3WS.Env{}` struct, or an MFA tuple.
          # In the MFA tuple case  the arguments will be a `%W3WS.Env{}` struct followed
          # by any arguments provided.
          # defaults to `W3WS.Handler.DefaultHandler` which logs received events.
          handler: {W3WS.Handler.BlockRemovalHandler, blocks: 12, handler: DexBot.Handler}

          # a list of log event topics to subscribe to for the given subscription. this is
          # optional. not passing `:topics` will subscribe to all log events. See
          # https://ethereum.org/en/developers/tutorials/using-websockets/#eth-subscribe
          # documentation for more details. If an abi is provided you can use short-hand event
          # names or event signatures (e.g. `Transfer(address,address,uint256)`) as topics.
          # Short-hand is also supported in nested "or" topics. Regardless of providing an abi,
          # you can always use hex topics (e.g.
          # `0x0148cba56e5d3a8d32fbcea206eae9e449ec0f0def4f642994b3edcd38561deb`).
          # topics: ["Sync"],
          # topics: ["Swap"]
          # topics: ["Transfer"],

          # address to limit the subscription to. this is optional. if not provided
          # events will be received for all addresses.
          # address: "0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f"
        ]
      ]
    ]
  ]
