defmodule CurrencyConverter do
  alias CurrencyConverter.{ConversionHistory, ExchangeRateCache, CBRClient}

  require Record

  Record.defrecordp(:conversion_token,
    result: nil,
    result_from_history: false,
    exchange_rates: nil,
    exchange_rates_from_cache: false
  )

  @type currency_iso :: String.t()
  @type exchange_rates_map :: %{currency_iso() => float()}

  @spec convert(float(), String.t(), Date.t()) :: {:ok, float} | {:error, atom()}
  def convert(amount, currency_iso, date) do
    conversion_token()
    |> get_result_from_history(amount, currency_iso, date)
    |> get_exchange_rates_from_cache(date)
    |> request_exchange_rates_from_cbr(date)
    |> put_exchange_rates_into_cache(date)
    |> calculate_conversion(amount, currency_iso)
    |> put_result_into_history(amount, currency_iso, date)
    |> unwrap_token()
  end

  defp get_result_from_history(token, amount, currency_iso, date) do
    result = ConversionHistory.get_conversion_result(amount, currency_iso, date)

    if result do
      conversion_token(token, result: {:ok, result}, result_from_history: true)
    else
      token
    end
  end

  defp get_exchange_rates_from_cache(conversion_token(result: nil) = token, date) do
    result = ExchangeRateCache.get(date)

    if result do
      conversion_token(token, exchange_rates: result, exchange_rates_from_cache: true)
    else
      token
    end
  end

  defp get_exchange_rates_from_cache(token, _date), do: token

  defp request_exchange_rates_from_cbr(
         conversion_token(result: nil, exchange_rates: nil) = token,
         date
       ) do
    result = CBRClient.request_exchange_rates(date)

    case result do
      {:ok, exchange_rates} -> conversion_token(token, exchange_rates: exchange_rates)
      # Если произошла ошибка, то кладём её в результат -
      # без обменного курса вычисление всё равно дальше не поедет
      {:error, _reason} -> conversion_token(token, result: result)
    end
  end

  defp request_exchange_rates_from_cbr(token, _date), do: token

  defp put_exchange_rates_into_cache(
         conversion_token(exchange_rates: rates, exchange_rates_from_cache: false) = token,
         date
       )
       when not is_nil(rates) do
    ExchangeRateCache.put(date, rates)
    token
  end

  defp put_exchange_rates_into_cache(token, _date), do: token

  defp calculate_conversion(
         conversion_token(result: nil, exchange_rates: rates) = token,
         amount,
         currency_iso
       )
       when not is_nil(rates) do
    rate = rates[currency_iso]

    result =
      if rate do
        {:ok, amount * rate}
      else
        {:error, :missing_exchange_rate}
      end

    conversion_token(token, result: result)
  end

  defp calculate_conversion(token, _amount, _currency_iso), do: token

  defp put_result_into_history(
         conversion_token(result: {:ok, result}, result_from_history: false) = token,
         amount,
         currency_iso,
         date
       ) do
    ConversionHistory.put_conversion(amount, currency_iso, date, result)
    token
  end

  defp put_result_into_history(token, _amount, _currency_iso, _date), do: token

  defp unwrap_token(conversion_token(result: result)), do: result
end
