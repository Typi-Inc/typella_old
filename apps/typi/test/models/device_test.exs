defmodule Typi.DeviceTest do
  use Typi.ModelCase, async: true
  alias Typi.Device

  @valid_attrs %{uuid: "599F9C00-92DC-4B5C-9464-7971F01F8370"}

  setup do
    user = insert_user
    {:ok, %{user: user}}
  end

  test "changeset is invalid if user_id is not specified" do
    changeset = Device.changeset(%Device{}, @valid_attrs)
    refute changeset.valid?
    assert {:user_id, {"can't be blank", []}} in changeset.errors
  end

  test "changeset is invalid if user_id is specified but user does not exist in database" do
    changeset = Device.changeset(%Device{}, Map.put(@valid_attrs, :user_id, 0))
    assert {:error, changeset} = Repo.insert(changeset)
    refute changeset.valid?
    assert {:user, {"does not exist", []}} in changeset.errors
  end

  test "changeset is valid with uuid and user_id specified and user existing in database", %{user: user} do
    changeset = device_changeset(user, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset is invalid if uuid is not specified", %{user: user} do
    changeset = device_changeset(user, Map.delete(@valid_attrs, :uuid))
    refute changeset.valid?
    assert {:uuid, {"can't be blank", []}} in changeset.errors
  end

  test "changeset is invalid if uuid is of not approproate format", %{user: user} do
    changeset  = device_changeset(user, Map.put(@valid_attrs, :uuid, "123"))
    refute changeset.valid?
    assert {:uuid, {"has invalid format", []}} in changeset.errors
  end

  test "changeset is invalid if uuid already exists", %{user: user} do
    insert_device(user, @valid_attrs)

    changeset = device_changeset(user, @valid_attrs)
    assert {:error, changeset} = Repo.insert(changeset)
    assert {:uuid, {"has already been taken", []}} in changeset.errors
  end
end
