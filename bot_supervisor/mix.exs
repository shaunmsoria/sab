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
      {:con_cache, "~> 1.0"},
      {:plug, "~> 1.11"},
      {:logger_file_backend, "~> 0.0.14"},
      {:plug_cowboy, "~> 2.5"},
      {:ecto_sql, "~> 3.2"},
      {:postgrex, "~> 0.15"},
      {:decimal, "~> 2.3.0"},
      {:ex_secp256k1, "~> 0.7.1"},
      {:timex, "~> 3.0"}
    ]
  end

  def application do
    [
      extra_applications: [:logger, :plug_cowboy],
      mod: {Server, []}
    ]
  end
end
