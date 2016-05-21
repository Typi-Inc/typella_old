defmodule Typi.RegistrationTest do
  use Typi.ModelCase, async: true
  alias Typi.Registration

  @valid_attrs %{"country_code": "+1", "region": "US",
    "number": "7012530000", "uuid": "599F9C00-92DC-4B5C-9464-7971F01F8370"}

  test "registration's to_user function generates user with device and phone associations" do
    changeset = Registration.changeset(%Registration{}, @valid_attrs)
    registration = Ecto.Changeset.apply_changes(changeset)
    user = Registration.to_user(registration)
    assert [struct(Typi.Device, @valid_attrs)] == user.devices
    assert [struct(Typi.Phone, @valid_attrs)] == user.phones
  end

  # This part duplicates functionality from Typi.Phone
  test "changeset is valid country code, region, number and uuid are specified" do
    changeset = Registration.changeset(%Registration{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset is invalid if country_code is not of appropriate format" do
    changeset = Registration.changeset(%Registration{}, Map.put(@valid_attrs, :country_code, "+123123"))
    refute changeset.valid?
    assert {:number, {"invalid phone number", []}} in changeset.errors
  end

  test "changeset is invalid if number is not of appropriate format" do
    changeset = Registration.changeset(%Registration{}, Map.put(@valid_attrs, :number, "123123123123123123123123123"))
    assert {:error, changeset} = Repo.insert(changeset)
    assert {:number, {"invalid phone number", []}} in changeset.errors
  end

  test "changeset is invalid if region's length is not in range (2, 3)" do
    changeset = Registration.changeset(%Registration{}, Map.put(@valid_attrs, :region, "ADASDA"))
    refute changeset.valid?
    assert {:region, {"should be at most %{count} character(s)", [count: 3]}} in changeset.errors

    changeset = Registration.changeset(%Registration{}, Map.put(@valid_attrs, :region, "A"))
    refute changeset.valid?
    assert {:region, {"should be at least %{count} character(s)", [count: 2]}} in changeset.errors
  end

  test "changeset is invalid if any attr (country code, region, number and uuid) are missing" do
    changeset = Registration.changeset(%Registration{}, %{})
    refute changeset.valid?

    changeset = Registration.changeset(%Registration{}, Map.take(@valid_attrs, [:country_code, :region, :number]))
    refute changeset.valid?

    changeset = Registration.changeset(%Registration{}, Map.take(@valid_attrs, [:country_code, :region, :uuid]))
    refute changeset.valid?

    changeset = Registration.changeset(%Registration{}, Map.take(@valid_attrs, [:number, :region, :uuid]))
    refute changeset.valid?

    changeset = Registration.changeset(%Registration{}, Map.take(@valid_attrs, [:country_code, :region]))
    refute changeset.valid?

    changeset = Registration.changeset(%Registration{}, Map.take(@valid_attrs, [:country_code, :number]))
    refute changeset.valid?

    changeset = Registration.changeset(%Registration{}, Map.take(@valid_attrs, [:country_code, :uuid]))
    refute changeset.valid?

    changeset = Registration.changeset(%Registration{}, Map.take(@valid_attrs, [:number, :region]))
    refute changeset.valid?

    changeset = Registration.changeset(%Registration{}, Map.take(@valid_attrs, [:region, :uuid]))
    refute changeset.valid?

    changeset = Registration.changeset(%Registration{}, Map.take(@valid_attrs, [:country_code]))
    refute changeset.valid?

    changeset = Registration.changeset(%Registration{}, Map.take(@valid_attrs, [:region]))
    refute changeset.valid?

    changeset = Registration.changeset(%Registration{}, Map.take(@valid_attrs, [:number]))
    refute changeset.valid?

    changeset = Registration.changeset(%Registration{}, Map.take(@valid_attrs, [:uuid]))
    refute changeset.valid?
  end
end
