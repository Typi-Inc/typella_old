defmodule Typi.PhoneTest do
  use Typi.ModelCase, async: true
  alias Typi.Phone

  @valid_attrs %{country_code: "+1", region: "US", number: "7012530000"}

  test "changeset is valid with country_code, number and region attributes specified" do
    changeset = Phone.changeset(%Phone{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset is invalid if any attribute (country_code, number or region) is missing" do
    changeset = Phone.changeset(%Phone{}, %{})
    refute changeset.valid?

    changeset = Phone.changeset(%Phone{}, Map.drop(@valid_attrs, [:country_code, :number]))
    refute changeset.valid?

    changeset = Phone.changeset(%Phone{}, Map.drop(@valid_attrs, [:country_code, :region]))
    refute changeset.valid?

    changeset = Phone.changeset(%Phone{}, Map.drop(@valid_attrs, [:number, :region]))
    refute changeset.valid?

    changeset = Phone.changeset(%Phone{}, Map.drop(@valid_attrs, [:country_code]))
    refute changeset.valid?

    changeset = Phone.changeset(%Phone{}, Map.drop(@valid_attrs, [:number]))
    refute changeset.valid?

    changeset = Phone.changeset(%Phone{}, Map.drop(@valid_attrs, [:region]))
    refute changeset.valid?
  end

  test "changeset is invalid if country_code/number combination already exists" do
    insert_phone(@valid_attrs)

    changeset = %Phone{}
    |> Phone.changeset(@valid_attrs)

    assert {:error, changeset} = Repo.insert(changeset)
    assert {:number, {"has already been taken", []}} in changeset.errors
  end

  test "changeset is valid if country_code(or number) already exists but number (or country_code) is different " do
      insert_phone(@valid_attrs)

      new_number = "7012530001"
      changeset = %Phone{}
      |> Phone.changeset(Map.put(@valid_attrs, :number, new_number))

      assert {:ok, %Phone{country_code: country_code, number: number}} = Repo.insert(changeset)
      assert number == new_number
      assert country_code == @valid_attrs[:country_code]

      new_country_code = "+7"
      changeset = %Phone{}
      |> Phone.changeset(Map.put(@valid_attrs, :country_code, new_country_code))

      assert {:ok, %Phone{country_code: country_code, number: number}} = Repo.insert(changeset)
      assert number == @valid_attrs[:number]
      assert country_code == new_country_code
  end

  test "changeset is invalid if country_code is not of appropriate format" do
    changeset = %Phone{}
    |> Phone.changeset(Map.put(@valid_attrs, :country_code, "+123123"))

    assert {:error, changeset} = Repo.insert(changeset)
    assert {:number, {"invalid phone number", []}} in changeset.errors
  end

  test "changeset is invalid if number is not of appropriate format" do
    changeset = %Phone{}
    |> Phone.changeset(Map.put(@valid_attrs, :number, "123123123123123123123123123"))

    assert {:error, changeset} = Repo.insert(changeset)
    assert {:number, {"invalid phone number", []}} in changeset.errors
  end

  test "changeset is invalid if region's length is not in range (2, 3)" do
    changeset = %Phone{}
    |> Phone.changeset(Map.put(@valid_attrs, :region, "ADASDA"))

    assert {:error, changeset} = Repo.insert(changeset)
    assert {:region, {"should be at most %{count} character(s)", [count: 3]}} in changeset.errors

    changeset = %Phone{}
    |> Phone.changeset(Map.put(@valid_attrs, :region, "A"))

    assert {:error, changeset} = Repo.insert(changeset)
    assert {:region, {"should be at least %{count} character(s)", [count: 2]}} in changeset.errors
  end
end
