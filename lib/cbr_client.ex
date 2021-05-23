defmodule CurrencyConverter.CBRClient do

  @base_url "https://www.cbr-xml-daily.ru"

  def request_cbr() do
    do_request_cbr("#{@base_url}/daily_json.js")
  end

  def request_cbr(date) do
    date |> request_url_for_date() |> do_request_cbr()
  end

  defp do_request_cbr(request_url) do
    with {:ok, response} <- HTTPoison.get(request_url),
         %HTTPoison.Response{body: body} = response,
         {:ok, data} <- Jason.decode(body),
         {:ok, parsed_data} <- parse_data(data)
    do
      {:ok, parsed_data}
    end
  end

  defp request_url_for_date(date) do
    date_part_of_url = Calendar.strftime(date, "%Y/%m/%d")
    "#{@base_url}/archive/#{date_part_of_url}/daily_json.js"
  end

  defp parse_data(%{"Valute" => valutes}) do
    try do
      {:ok, Map.new(valutes, &parse_valute/1)}
    catch
      :bad_valute_rate -> {:error, :bad_data}
    end
  end
  defp parse_data(_data), do: {:error, :bad_data}

  defp parse_valute({currency_iso, valute_data}) do
    valute_rate = parse_valute_rate(valute_data)
    {currency_iso, valute_rate}
  end

  defp parse_valute_rate(%{"Value" => value}) when is_float(value), do: value
  defp parse_valute_rate(_data), do: throw :bad_valute_rate
end
