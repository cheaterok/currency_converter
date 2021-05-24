defmodule ConversionHistoryTest do
  use ExUnit.Case

  alias CurrencyConverter.ConversionHistory

  @date ~D[2020-12-12]

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(ConversionHistory.Repo)
  end

  test "сохраняет конвертацию" do
    ConversionHistory.put_conversion(3.0, "USD", ~D[2020-12-12], 4.0)

    assert 4.0 == ConversionHistory.get_conversion_result(3.0, "USD", @date)
  end

  test "возвращает nil если конвертации не существует" do
    assert nil == ConversionHistory.get_conversion_result(0.0, "RUB", @date)
  end

  test "учитывает каждый параметр при поиске конвертации" do
    ConversionHistory.put_conversion(3.0, "USD", @date, 4.0)

    assert nil == ConversionHistory.get_conversion_result(3.1, "USD", @date)
    assert nil == ConversionHistory.get_conversion_result(3.0, "EUR", @date)
    assert nil == ConversionHistory.get_conversion_result(3.0, "USD", Date.add(@date, 1))
    assert 4.0 == ConversionHistory.get_conversion_result(3.0, "USD", @date)
  end
end
