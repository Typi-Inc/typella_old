defmodule Typi.Repo.Migrations.CreateMessage do
  use Ecto.Migration

  def change do
    create table(:messages) do
      add :client_id, :integer, null: false
      add :body, :string, null: false
      add :status, :string, null: false
      add :future_datetime, :datetime
      add :created_at, :datetime, null: false
      add :sender_id, references(:users, on_delete: :nothing), null: false

      timestamps
    end

    create index(:messages, [:sender_id])
  end
end
