defmodule CurrencyConverter.ConversionHistory do
  defmodule Repo do
    use Ecto.Repo,
      otp_app: :currency_converter,
      adapter: Ecto.Adapters.Postgres
  end

  defmodule Conversion do
    use Ecto.Schema

    schema "conversions" do
      field :currency_iso, :string
      field :amount, :float
      field :date, :date
      field :result, :float
    end
  end

  @spec get_conversion_result(float(), CurrencyConverter.currency_iso(), Date.t()) :: float() | nil
  def get_conversion_result(amount, currency_iso, date) do
    require Ecto.Query

    conversion =
      Conversion
      |> Ecto.Query.where(currency_iso: ^currency_iso, amount: ^amount, date: ^date)
      |> Ecto.Query.select([:result])
      |> Repo.one()

    if conversion, do: conversion.result, else: nil
  end

  @spec put_conversion(float(), CurrencyConverter.currency_iso(), Date.t(), float()) :: :ok
  def put_conversion(amount, currency_iso, date, result) do
    conversion = %Conversion{
      currency_iso: currency_iso,
      amount: amount,
      date: date,
      result: result
    }
    {:ok, _conversion} = Repo.insert(conversion)

    :ok
  end
end
