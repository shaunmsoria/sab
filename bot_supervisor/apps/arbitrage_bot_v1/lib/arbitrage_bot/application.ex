defmodule ArbitrageBotV1.Application do
  # @moduledoc false
  use Application



  def start(_type, []) do
    children = [
      {DexBot,
       []},
      {W3WS.ListenerManager, otp_app: :arbitrage_bot_v1}
    ]

    opts = [strategy: :one_for_one]
    Supervisor.start_link(children, opts)
  end

end
