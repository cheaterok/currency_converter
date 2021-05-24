defmodule CurrencyConverter.MixProject do
  use Mix.Project

  def project do
    [
      app: :currency_converter,
      version: "0.1.0",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {CurrencyConverter.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:httpoison, "~> 1.7"},
      {:jason, "~> 1.2"},
      {:cachex, "~> 3.3"},
      {:ecto_sql, "~> 3.6"},
      {:postgrex, "~> 0.15"},
      {:mock, "~> 0.3.7", only: [:test]},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:credo, "~> 1.5", only: [:dev, :test], runtime: false}
    ]
  end

  defp aliases do
    [
      test: ["ecto.create --quiet", "ecto.migrate", "test"]
    ]
  end
end
