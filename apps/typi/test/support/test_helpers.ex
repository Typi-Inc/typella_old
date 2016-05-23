defmodule Typi.TestHelpers do
  alias Typi.{Repo, Device, Phone, User}

  def insert_device(user, attrs \\ %{}) do
    user
    |> Ecto.build_assoc(:devices, attrs)
    |> Repo.insert!
  end

  def device_changeset(user, attrs \\ %{}) do
    user
    |> Ecto.build_assoc(:devices)
    |> Device.changeset(attrs)
  end

  def insert_phone(user, attrs \\ %{}) do
    user
    |> Ecto.build_assoc(:phones, attrs)
    |> Repo.insert!
  end

  def phone_changeset(user, attrs \\ %{}) do
    user
    |> Ecto.build_assoc(:phones)
    |> Phone.changeset(attrs)
  end

  def insert_user(user \\ %User{}) do
    user
    |> Repo.insert!
  end
end
