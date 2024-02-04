defmodule ArbitrageBotV1.Application do
  # @moduledoc false
  use Application

  def start(_type, %{
    dex0: dex0,
    dex1: dex1,
    pairs: pairs
  }) do


    children = [
      {DexBot,
        %DexPair{
            dex0: dex0,
            dex1: dex1,
            pairs: pairs
        }
      }
    ]

    opts = [strategy: :one_for_one]
    Supervisor.start_link(children, opts)
  end
end
