defmodule CurrencyConverter do
  alias CurrencyConverter.CBRClient

  @type currency_iso :: String.t()
  @type exchange_rates_map :: %{currency_iso() => float()}

  @spec convert(float(), String.t(), Date.t()) :: {:ok, float} | {:error, atom()}
  def convert(amount, currency_iso, date) do
    with {:ok, rates} <- CBRClient.request_exchange_rates(date),
         {:ok, rate} <- Map.fetch(rates, currency_iso) do
      {:ok, amount * rate}
    end
  end
end
