defmodule CurrencyConverter.CBRClient do

  @base_url "https://www.cbr-xml-daily.ru"

  @spec request_exchange_rates(Date.t()) ::
          {:ok, CurrencyConverter.exchange_rates_map()}
          | {:error, :request_error | :json_decode_error | :parsing_error}
  def request_exchange_rates(date) do
    request_url = request_url_for_date(date)

    with {_, {:ok, response}} <- {:request, HTTPoison.get(request_url)},
         %HTTPoison.Response{body: body} = response,
         {_, {:ok, data}} <- {:json, Jason.decode(body)},
         {_, {:ok, parsed_data}} <- {:parsing, __MODULE__.Parser.parse_data(data)}
    do
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
  # JSON example
  _ = """
  {
    "Valute": {
        "AUD": {
            "Value": 53.0613,
        },
        "AZN": {
            "Value": 43.5942,
        },
        ...
    }
  }
  """

  @spec parse_data(map()) :: {:ok, CurrencyConverter.exchange_rates_map()} | :error
  def parse_data(data) do
    with %{"Valute" => valutes} <- data,
         {:ok, result} <- parse_valutes(valutes)
    do
      {:ok, result}
    else
      _ -> :error
    end
  end

  defp parse_valutes(valutes) do
    reducer = fn element, acc ->
      case element do
        {name, %{"Value" => value}} when is_float(value) ->
          {:cont, Map.put(acc, name, value)}
        _ ->
          {:halt, :error}
      end
    end
    result = Enum.reduce_while(valutes, %{}, reducer)

    case result do
      :error -> :error
      map -> {:ok, map}
    end
  end
end
