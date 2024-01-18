defmodule ArbitrageBotV1.Application do
  @moduledoc false
  use Application

  def start(_type, _args) do
    children = [
      {Ethers, []}
    # {ArbitrageBotV1.Worker, arg},
    ]
    opts = [strategy: :one_for_one, name: ArbitrageBotV1.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
