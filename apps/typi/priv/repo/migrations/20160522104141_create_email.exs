defmodule Typi.Repo.Migrations.CreateEmail do
  use Ecto.Migration

  def change do
    create table(:emails) do
      add :email_id, :string
      add :value, :string
      add :user_id, references(:contacts, on_delete: :nothing)
      add :contact_id, references(:contacts, on_delete: :nothing)

      timestamps()
    end

    create index(:emails, [:user_id])
    create index(:emails, [:contact_id])
    create unique_index(:emails, [:value])
  end
end
