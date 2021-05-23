defmodule CurrencyConverter.ExchangeRateCache do
  @cache_name __MODULE__
  @default_ttl :timer.seconds(3)

  require Cachex.Spec

  @spec child_spec([]) :: Supervisor.child_spec()
  def child_spec([]) do
    Cachex.child_spec([
      name: @cache_name,
      expiration: Cachex.Spec.expiration(default: @default_ttl)
    ])
  end

  @spec get(Date.t()) :: nil | CurrencyConverter.exchange_rate_map()
  def get(date) do
    Cachex.get!(@cache_name, date)
  end

  @spec put(Date.t(), CurrencyConverter.exchange_rate_map()) :: :ok
  def put(date, value) do
    Cachex.put!(@cache_name, date, value)
  end
end
