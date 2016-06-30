defmodule Typi.Repo.Migrations.CreatePhone do
  use Ecto.Migration

  def change do
    create table(:phones) do
      add :country_code, :string, null: false
      add :number, :string, null: false
      add :phone_identifier, :string
      add :region, :string
      add :user_id, references(:users, on_delete: :nothing)
      add :contact_id, references(:contacts, on_delete: :nothing)

      timestamps
    end

    create index(:phones, [:user_id])
    create index(:phones, [:contact_id])
    create unique_index(:phones, [:country_code, :number])
  end
end
