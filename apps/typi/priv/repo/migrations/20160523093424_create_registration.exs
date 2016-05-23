defmodule Typi.Repo.Migrations.CreateRegistration do
  use Ecto.Migration

  def change do
    create table(:registrations) do
      add :country_code, :string, null: false
      add :number, :string, null: false
      add :region, :string, null: false
      add :uuid, :string, null: false
      add :otp_hash, :string, null: false

      timestamps
    end
  end
end
