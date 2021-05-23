defmodule CurrencyConverter.ConversionHistory.Repo.Migrations.CreateConversions do
  use Ecto.Migration

  def change do
    create table(:conversions) do
      add :currency_iso, :string
      add :amount, :float
      add :date, :date
      add :result, :float
    end
  end
end
