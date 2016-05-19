defmodule Typi.Repo.Migrations.CreateDevice do
  use Ecto.Migration

  def change do
    create table(:devices) do
      add :uuid, :string
      add :user_id, references(:users, on_delete: :nothing)

      timestamps
    end

    create index(:devices, [:user_id])
    create unique_index(:devices, [:uuid])
  end
end
