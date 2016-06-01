defmodule Typi.TestHelpers do
  alias Typi.{Repo, Device, Phone, User, Registration, Chat}

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

  def insert_registration(attrs \\ %{}) do
    attrs = Map.merge(%{
      :otp => "1234"
    }, attrs)

    %Registration{}
    |> Registration.changeset(attrs)
    |> Repo.insert!
  end

  def insert_chat(chat \\ %Chat{}) do
    chat
    |> Repo.insert!
  end
end
