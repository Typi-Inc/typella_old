defmodule Typi.TestHelpers do
  alias Typi.Repo
  alias Typi.Device
  alias Typi.Phone

  def insert_device(attrs \\ %{}) do
    %Device{}
    |> Device.changeset(attrs)
    |> Repo.insert!
  end

  def insert_phone(attrs \\ %{}) do
    %Phone{}
    |> Phone.changeset(attrs)
    |> Repo.insert!
  end
end
