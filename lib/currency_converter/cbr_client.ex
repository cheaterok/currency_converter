defmodule CurrencyConverter.CBRClient do
  alias __MODULE__.Parser

  @base_url "https://www.cbr-xml-daily.ru"

  @spec request_exchange_rates(Date.t()) ::
          {:ok, CurrencyConverter.exchange_rates_map()}
          | {:error, :request_error | :json_decode_error | :parsing_error}
  def request_exchange_rates(date) do
    request_url = request_url_for_date(date)

    with {_, {:ok, response}} <- {:request, HTTPoison.get(request_url)},
         %HTTPoison.Response{body: body} = response,
         {_, {:ok, data}} <- {:json, Jason.decode(body)},
         {_, {:ok, parsed_data}} <- {:parsing, Parser.parse_data(data)} do
      {:ok, parsed_data}
    else
      {error_stage, _error} ->
        error_atom = error_stage_to_error_atom(error_stage)
        {:error, error_atom}
    end
  end

  defp request_url_for_date(date) do
    if date == Date.utc_today() do
      # Данные ещё не успели попасть в архив
      "#{@base_url}/daily_json.js"
    else
      date_part_of_url = Calendar.strftime(date, "%Y/%m/%d")
      "#{@base_url}/archive/#{date_part_of_url}/daily_json.js"
    end
  end

  defp error_stage_to_error_atom(error_stage) do
    case error_stage do
      :request -> :request_error
      :json -> :json_decode_error
      :parsing -> :parsing_error
    end
  end
end

defmodule CurrencyConverter.CBRClient.Parser do
  def parse_data(data) do
    with {:ok, valutes} <- Map.fetch(data, "Valute"),
         {:ok, parsed_valutes} <- parse_valutes(valutes) do
      {:ok, parsed_valutes}
    else
      _ -> {:error, :bad_data}
    end
  end

  def parse_valutes(valutes) do
    try do
      {:ok, Map.new(valutes, &parse_valute/1)}
    catch
      :bad_valute_rate -> :error
    end
  end

  defp parse_valute({currency_iso, valute_data}) do
    valute_rate = parse_valute_rate(valute_data)
    {currency_iso, valute_rate}
  end

  defp parse_valute_rate(%{"Value" => value}) when is_float(value), do: value
  defp parse_valute_rate(_data), do: throw(:bad_valute_rate)
end
