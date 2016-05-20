defmodule Typi.Repo.Migrations.CreateDevice do
  use Ecto.Migration

  def change do
    create table(:devices) do
      add :uuid, :string, null: false
      add :user_id, references(:users, on_delete: :nothing), null: false

      timestamps
    end

    create index(:devices, [:user_id])
    create unique_index(:devices, [:uuid])
  end
end
