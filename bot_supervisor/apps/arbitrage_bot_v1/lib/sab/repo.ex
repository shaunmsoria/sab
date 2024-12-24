defmodule Repo do
  use Ecto.Repo,
    otp_app: :arbitrage_bot_v1,
    adapter: Ecto.Adapters.Postgres
end
