defmodule CurrencyConverter do
  alias CurrencyConverter.CBRClient

  @spec convert(float(), String.t(), Date.t()) :: {:ok, float} | {:error, atom()}
  def convert(amount, currency_iso, date) do
    with {:ok, rates} <- CBRClient.request_cbr(date),
         {:ok, rate} <- Map.fetch(rates, currency_iso)
    do
      {:ok, amount * rate}
    end
  end
end
