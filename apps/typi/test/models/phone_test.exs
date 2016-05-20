defmodule Typi.PhoneTest do
  use Typi.ModelCase, async: true
  alias Typi.Phone

  @valid_attrs %{country_code: "+1", region: "US", number: "7012530000"}

  setup do
    user = insert_user
    {:ok, %{user: user}}
  end

  test "changeset is invalid if user_id is not specified" do
    changeset = Phone.changeset(%Phone{}, @valid_attrs)
    refute changeset.valid?
    assert {:user_id, {"can't be blank", []}} in changeset.errors
  end

  test "changeset is invalid if user_id is specified but user does not exist in database" do
    changeset = Phone.changeset(%Phone{}, Map.put(@valid_attrs, :user_id, 0))
    assert {:error, changeset} = Repo.insert(changeset)
    refute changeset.valid?
    assert {:user, {"does not exist", []}} in changeset.errors
  end

  test "changeset is valid with country_code, number and region specified and user existing in database", %{user: user} do
    changeset = phone_changeset(user, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset is invalid if any attribute (country_code, number or region) is missing" do
    changeset = Phone.changeset(%Phone{}, %{})
    refute changeset.valid?

    changeset = Phone.changeset(%Phone{}, Map.take(@valid_attrs, [:country_code, :number]))
    refute changeset.valid?

    changeset = Phone.changeset(%Phone{}, Map.take(@valid_attrs, [:country_code, :region]))
    refute changeset.valid?

    changeset = Phone.changeset(%Phone{}, Map.take(@valid_attrs, [:number, :region]))
    refute changeset.valid?

    changeset = Phone.changeset(%Phone{}, Map.take(@valid_attrs, [:country_code]))
    refute changeset.valid?

    changeset = Phone.changeset(%Phone{}, Map.take(@valid_attrs, [:number]))
    refute changeset.valid?

    changeset = Phone.changeset(%Phone{}, Map.take(@valid_attrs, [:region]))
    refute changeset.valid?
  end

  test "changeset is invalid if country_code/number combination already exists", %{user: user} do
    insert_phone(user, @valid_attrs)

    changeset = phone_changeset(user, @valid_attrs)
    assert {:error, changeset} = Repo.insert(changeset)
    assert {:number, {"has already been taken", []}} in changeset.errors
  end

  test "changeset is valid if country_code(or number) already exists but number (or country_code) is different", %{user: user} do
      insert_phone(user, @valid_attrs)

      new_number = "7012530001"
      changeset = phone_changeset(user, Map.put(@valid_attrs, :number, new_number))
      assert {:ok, %Phone{country_code: country_code, number: number}} = Repo.insert(changeset)
      assert number == new_number
      assert country_code == @valid_attrs[:country_code]

      new_country_code = "+7"
      changeset = phone_changeset(user, Map.put(@valid_attrs, :country_code, new_country_code))
      assert {:ok, %Phone{country_code: country_code, number: number}} = Repo.insert(changeset)
      assert number == @valid_attrs[:number]
      assert country_code == new_country_code
  end

  test "changeset is invalid if country_code is not of appropriate format", %{user: user} do
    changeset = phone_changeset(user, Map.put(@valid_attrs, :country_code, "+123123"))
    assert {:error, changeset} = Repo.insert(changeset)
    assert {:number, {"invalid phone number", []}} in changeset.errors
  end

  test "changeset is invalid if number is not of appropriate format", %{user: user} do
    changeset = phone_changeset(user, Map.put(@valid_attrs, :number, "123123123123123123123123123"))
    assert {:error, changeset} = Repo.insert(changeset)
    assert {:number, {"invalid phone number", []}} in changeset.errors
  end

  test "changeset is invalid if region's length is not in range (2, 3)", %{user: user} do
    changeset = phone_changeset(user, Map.put(@valid_attrs, :region, "ADASDA"))
    assert {:error, changeset} = Repo.insert(changeset)
    assert {:region, {"should be at most %{count} character(s)", [count: 3]}} in changeset.errors

    changeset = phone_changeset(user, Map.put(@valid_attrs, :region, "A"))
    assert {:error, changeset} = Repo.insert(changeset)
    assert {:region, {"should be at least %{count} character(s)", [count: 2]}} in changeset.errors
  end
end
