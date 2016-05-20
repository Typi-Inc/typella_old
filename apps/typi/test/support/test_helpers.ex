defmodule Typi.TestHelpers do
  alias Typi.Repo
  alias Typi.Device
  alias Typi.Phone
  alias Typi.User

  def insert_device(user, attrs \\ %{}) do
    user
    |> Ecto.build_assoc(:devices, attrs)
    |> Repo.insert!
  end

  def device_changeset(user, attrs) do
    user
    |> Ecto.build_assoc(:devices)
    |> Device.changeset(attrs)
  end

  def insert_phone(attrs \\ %{}) do
    %Phone{}
    |> Phone.changeset(attrs)
    |> Repo.insert!
  end

  def insert_user(attrs \\ %{}) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert!
  end
end
