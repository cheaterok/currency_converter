defmodule CBRClientTest do
  use ExUnit.Case

  alias CurrencyConverter.CBRClient

  import Mock

  @date ~D[2020-12-12]

  test "возвращает обменные курсы при успешном выполнении" do
    cbr_response = ~s(
      {
        "Valute": {
          "USD": {
              "Value": 35.0
          }
        }
      }
    )

    with_mock HTTPoison, [get: fn(_url) -> {:ok, %HTTPoison.Response{body: cbr_response}} end] do
      assert {:ok, %{"USD" => 35.0}} == CBRClient.request_exchange_rates(@date)
    end
  end

  test "возвращает :request_error при ошибке запроса в CBR" do
    with_mock HTTPoison, [get: fn(_url) -> {:error, %HTTPoison.Error{}} end] do
      assert {:error, :request_error} == CBRClient.request_exchange_rates(@date)
    end
  end

  test "возвращает :json_decode_error при получении некорректного json от CBR" do
    bad_cbr_response = ~s(
      {
        "Valute": bad_value,,,.
      }
    )

    with_mock HTTPoison, [get: fn(_url) -> {:ok, %HTTPoison.Response{body: bad_cbr_response}} end] do
      assert {:error, :json_decode_error} == CBRClient.request_exchange_rates(@date)
    end
  end

  test "возвращает :parsing_error при получении неполных данных от CBR" do
    bad_cbr_response = ~s(
      {
        "Valute": {
          "USD": 300
        }
      }
    )

    with_mock HTTPoison, [get: fn(_url) -> {:ok, %HTTPoison.Response{body: bad_cbr_response}} end] do
      assert {:error, :parsing_error} == CBRClient.request_exchange_rates(@date)
    end
  end
end
