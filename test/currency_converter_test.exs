defmodule CurrencyConverterTest do
  use ExUnit.Case

  alias CurrencyConverter.{ConversionHistory, ExchangeRateCache}

  import Mock

  @amount 3.0
  @currency_iso "USD"
  @date ~D[2020-12-12]

  @exchange_rate 1.5
  @exchange_rates %{@currency_iso => @exchange_rate}

  @result @amount * @exchange_rate

  setup_with_mocks [
    {ConversionHistory, [:passthrough], []},
    {ExchangeRateCache, [:passthrough], []}
  ] do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(ConversionHistory.Repo)
    on_exit(&ExchangeRateCache.clear/0)
  end

  test "берёт результат конвертации из истории" do
    ConversionHistory.put_conversion(@amount, @currency_iso, @date, @result)
    assert {:ok, @result} == CurrencyConverter.convert(@amount, @currency_iso, @date)

    # Не сохраняет обменные курсы в кэш
    assert_not_called ExchangeRateCache.put(@date, @exchange_rates)
    # Не сохраняет результат в историю
    assert_called_exactly ConversionHistory.put_conversion(@amount, @currency_iso, @date, @result), 1
  end

  test "берёт обменные курсы из кэша" do
    ExchangeRateCache.put(@date, @exchange_rates)
    assert {:ok, @result} == CurrencyConverter.convert(@amount, @currency_iso, @date)

    # Не сохраняет обменные курсы в кэш
    assert_called_exactly ExchangeRateCache.put(@date, @exchange_rates), 1
    # Сохраняет результат в историю
    assert_called ConversionHistory.put_conversion(@amount, @currency_iso, @date, @result)
  end

  test "получает обменные курсы от CDR" do
    cbr_response = %{
      "Valute" => %{
        @currency_iso => %{
          "Value" => @exchange_rate
        }
      }
    } |> Jason.encode!()

    with_mock HTTPoison, [get: fn(_url) -> {:ok, %HTTPoison.Response{body: cbr_response}} end] do
      assert {:ok, @result} == CurrencyConverter.convert(@amount, @currency_iso, @date)
    end

    # Сохраняет обменные курсы в кэш
    assert_called ExchangeRateCache.put(@date, @exchange_rates)
    # Сохраняет результат в историю
    assert_called ConversionHistory.put_conversion(@amount, @currency_iso, @date, @result)
  end

  test "ошибка при получении обменных курсов от CDR" do
    with_mock HTTPoison, [get: fn(_url) -> {:error, %HTTPoison.Error{}} end] do
      assert {:error, :request_error} == CurrencyConverter.convert(@amount, @currency_iso, @date)
    end
    # Не сохраняет обменные курсы в кэш
    assert_not_called ExchangeRateCache.put(@date, @exchange_rates)
    # Не сохраняет результат в историю
    assert_not_called ConversionHistory.put_conversion(@amount, @currency_iso, @date, @result)
  end

  test "в обменных курсах от CDR нет нужной валюты" do
    cbr_response = %{
      "Valute" => %{
        "EUR" => %{
          "Value" => 200.0
        }
      }
    } |> Jason.encode!()
    with_mock HTTPoison, [get: fn(_url) -> {:ok, %HTTPoison.Response{body: cbr_response}} end] do
      assert {:error, :missing_exchange_rate} == CurrencyConverter.convert(@amount, @currency_iso, @date)
    end
    # Сохраняет обменные курсы в кэш
    assert_called ExchangeRateCache.put(@date, %{"EUR" => 200.0})
    # Не сохраняет результат в историю
    assert_not_called ConversionHistory.put_conversion(@amount, @currency_iso, @date, @result)
  end
end
