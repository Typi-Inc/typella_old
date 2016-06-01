defmodule Typi.Repo.Migrations.AddChatIdToMessage do
  use Ecto.Migration

  def change do
    alter table(:messages) do
      add :chat_id, references(:chats, on_delete: :nothing), null: false
    end

    create index(:messages, [:chat_id])
  end
end
