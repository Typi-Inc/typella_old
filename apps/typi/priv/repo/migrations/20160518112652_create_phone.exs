defmodule Typi.Repo.Migrations.CreatePhone do
  use Ecto.Migration

  def change do
    create table(:phones) do
      add :country_code, :string, null: false
      add :number, :string, null: false
      add :region, :string, null: false
      add :user_id, references(:users, on_delete: :nothing), null: false

      timestamps
    end

    create index(:phones, [:user_id])
    create unique_index(:phones, [:country_code, :number])
  end
end
