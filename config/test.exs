import Config

config :currency_converter, CurrencyConverter.ConversionHistory.Repo,
  pool: Ecto.Adapters.SQL.Sandbox

config :logger, level: :info
