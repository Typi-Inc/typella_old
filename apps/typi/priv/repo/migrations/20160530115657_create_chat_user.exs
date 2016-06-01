defmodule Typi.Repo.Migrations.CreateChatUser do
  use Ecto.Migration

  def change do
    create table(:chats_users) do
      add :is_admin, :boolean, default: false, null: false
      add :chat_id, references(:chats, on_delete: :nothing), null: false
      add :user_id, references(:users, on_delete: :nothing), null: false

      timestamps
    end
    create index(:chats_users, [:chat_id])
    create index(:chats_users, [:user_id])

  end
end
