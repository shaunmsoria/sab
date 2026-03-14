defmodule ArbitrageBotV1.Application do
  # @moduledoc false
  use Application

  def start(_type, []) do
    children = [
      #  ArbitrageBotV1.Repo,
      Repo,
      Supervisor.child_spec({ConCache, [name: :logs, ttl_check_interval: false]},
        id: :con_cache_logs
      ),
      Supervisor.child_spec({ConCache, [name: :gas, ttl_check_interval: false]},
        id: :con_cache_gas
      ),
      Supervisor.child_spec({ConCache, [name: :tokens, ttl_check_interval: false]},
        id: :con_cache_tokens
      ),
      Supervisor.child_spec({ConCache, [name: :system, ttl_check_interval: false]},
        id: :con_cache_system
      ),
      {LogSaver, []},
      {Timer, %{}},
      {DexBot, []},
      {W3WS.ListenerManager, otp_app: :arbitrage_bot_v1}
    ]

    opts = [strategy: :one_for_one]
    Supervisor.start_link(children, opts)
  end
end


#  PAS.with_upcase_address("0X9E5F2B740E52C239DA457109BCCED1F2BB40DA5B") |> PAS.with_status("active") |> Repo.one()
