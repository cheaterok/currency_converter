defmodule ExchangeRateCacheTest do
  use ExUnit.Case

  alias CurrencyConverter.ExchangeRateCache

  setup do
    on_exit(&ExchangeRateCache.clear/0)
  end

  @date ~D[2020-12-12]
  @exchange_rates_map %{"USD" => 35.0}

  test "возвращает nil когда значения нет" do
    assert nil == ExchangeRateCache.get(@date)
  end

  test "возвращает значение когда оно есть" do
    ExchangeRateCache.put(@date, @exchange_rates_map)
    assert @exchange_rates_map == ExchangeRateCache.get(@date)
  end

  test "хранит значение только 3 секунды" do
    ExchangeRateCache.put(@date, @exchange_rates_map)
    Process.sleep(2_500)
    assert @exchange_rates_map == ExchangeRateCache.get(@date)
    Process.sleep(1_000)
    assert nil == ExchangeRateCache.get(@date)
  end

end
