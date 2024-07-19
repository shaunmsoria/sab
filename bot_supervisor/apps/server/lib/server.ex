defmodule Server do
  @moduledoc """
  Documentation for SimpleHttpServer.
  """

  use Application

  def start(_type, _args) do
    Server.Application.start(:normal, [])
  end
end
