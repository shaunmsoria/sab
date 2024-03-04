defmodule ArbitrageBotV1.MixProject do
  use Mix.Project

  def project do
    [
      app: :arbitrage_bot_v1,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.17-dev",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    ##TODO restruct the state to remove dex0 dex1 and pairs to only have an empty map
    [
      mod: {
        ArbitrageBotV1.Application,
        %{
          dex0: :uniswap,
          dex1: :sushiswap,
          pairs: %{}
        }
      },
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:jason, "~> 1.2"},
      {:ethers, "~> 0.2.2"},
      {:w3ws, "~> 0.3.0"},
      {:httpoison, "~> 2.2"}
    ]
  end
end
