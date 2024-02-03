defmodule ArbitrageBotV1.Application do
  # @moduledoc false
  use Application

  # def start(_type, %{
  #   dex0: dex0,
  #   dex1: dex1,
  #   pairs: pairs
  # }) do


  #   children = [
  #     worker(
  #       DexBot,
  #       :persistent_term.get(
  #         :dexbot_state,
  #         %DexPair{
  #           dex0: dex0,
  #           dex1: dex1,
  #           pairs: pairs
  #         }
  #       )
  #     )


  #     # {DexBot, %DexPair{
  #     #   dex0: dex0,
  #     #   dex1: dex1,
  #     #   pairs: pairs
  #     # }}
  #   ]
  #   opts = [strategy: :restart, name: ArbitrageBotV1.Supervisor]
  #   Supervisor.start_link(children, strategy: :one_for_one, extra: opts)
  # end

  def start(_type, %{
    dex0: dex0,
    dex1: dex1,
    pairs: pairs
  }) do


    children = [
      {DexBot, %DexPair{
        dex0: dex0,
        dex1: dex1,
        pairs: pairs
      }}
    ]
    opts = [strategy: :restart, name: ArbitrageBotV1.Supervisor]
    Supervisor.start_link(children, strategy: :one_for_one, extra: opts)
  end



end
