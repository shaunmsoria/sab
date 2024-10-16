defmodule ArbitrageBotV1.Application do
  # @moduledoc false
  use Application

  def start(_type, []) do
    children = [
      Supervisor.child_spec({ConCache, [name: :logs, ttl_check_interval: false]},
        id: :con_cache_logs
      ),
      Supervisor.child_spec({ConCache, [name: :dex, ttl_check_interval: false]},
        id: :con_cache_dex
      ),
      Supervisor.child_spec({ConCache, [name: :gas, ttl_check_interval: false]},
        id: :con_cache_gas
      ),
      Supervisor.child_spec({ConCache, [name: :tokens, ttl_check_interval: false]},
      id: :con_cache_tokens
    ),
      {LogSaver, []},
      {GasExtractor, %{}},
      {DexBot, []},
      {W3WS.ListenerManager, otp_app: :arbitrage_bot_v1}
    ]

    opts = [strategy: :one_for_one]
    Supervisor.start_link(children, opts)
  end
end
