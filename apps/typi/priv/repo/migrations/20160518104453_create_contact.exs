defmodule Typi.Repo.Migrations.CreateContact do
  use Ecto.Migration

  def change do
    create table(:contacts) do
      add :contact_id, :string
      add :full_name, :string
      add :user_id, references(:users, on_delete: :nothing), null: false

      timestamps()
    end
  end
end
