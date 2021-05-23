import Config

config :currency_converter, ecto_repos: [
  CurrencyConverter.ConversionHistory.Repo
]

config :currency_converter, CurrencyConverter.ConversionHistory.Repo,
  database: "currency_converter",
  username: "postgres",
  password: "secure_password",
  hostname: "postgres"
