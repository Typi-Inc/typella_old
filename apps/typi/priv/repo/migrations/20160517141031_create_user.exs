defmodule Typi.Repo.Migrations.CreateUser do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :name, :string
      add :profile_pic, :string

      timestamps
    end

  end
end
