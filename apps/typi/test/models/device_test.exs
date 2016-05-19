defmodule Typi.DeviceTest do
  use Typi.ModelCase, async: true
  alias Typi.Device

  test "changeset is valid with uuid specified" do
    changeset = Device.changeset(%Device{}, %{uuid: "1"})
    assert changeset.valid?
  end

  test "changeset is invalid with uuid not specified" do
    changeset = Device.changeset(%Device{}, %{})
    refute changeset.valid?
  end

  test "changeset is invalid if uuid already exists" do
    attrs = %{uuid: "1"}
    insert_device(attrs)

    changeset = %Device{}
    |> Device.changeset(attrs)

    assert {:error, changeset} = Repo.insert(changeset)
    assert {:uuid, {"has already been taken", []}} in changeset.errors
  end
end
