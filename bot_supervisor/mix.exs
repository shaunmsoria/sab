defmodule BotSupervisor.MixProject do
  use Mix.Project

  def project do
    [
      apps_path: "apps",
      version: "0.1.0",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Dependencies listed here are available only for this
  # project and cannot be accessed from applications inside
  # the apps folder.
  #
  # Run "mix help deps" for examples and options.
  defp deps do
    [
      {:jason, "~> 1.2"},
      {:ethers, "~> 0.2.2"},
      {:w3ws, "~> 0.3.0"},
      {:httpoison, "~> 2.2"},
      {:con_cache, "~> 1.0"}
    ]
  end

  def application do
    [
      extra_applications: [:logger]
      # extra_applications: [:logger, :con_cache]
    ]
  end
end
