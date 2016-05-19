defmodule Typi.PhoneTest do
  use Typi.ModelCase, async: true
  alias Typi.Phone

  @valid_attrs %{country_code: "some content", number: "some content"}
  @invalid_attrs %{}

  test "changeset is valid with country_code and number attributes specified" do
    changeset = Phone.changeset(%Phone{}, %{country_code: "+1", number: "123123123"})
    assert changeset.valid?
  end

  test "changeset is invalid if either of country_code or number attribute is missing" do
    changeset = Phone.changeset(%Phone{}, %{})
    refute changeset.valid?

    changeset = Phone.changeset(%Phone{}, %{country_code: "+1"})
    refute changeset.valid?

    changeset = Phone.changeset(%Phone{}, %{number: "123123123"})
    refute changeset.valid?
  end

  test "changeset is invalid if country_code/number combination already exists" do
    attrs = %{country_code: "+1", number: "123123123"}
    insert_phone(attrs)

    changeset = %Phone{}
    |> Phone.changeset(attrs)

    assert {:error, changeset} = Repo.insert(changeset)
    assert {:number, {"has already been taken", []}} in changeset.errors
  end

  test "changeset is valid if country_code(or number) already exists but number (or country_code) is different " do
      attrs = %{country_code: "+1", number: "123123123"}
      insert_phone(attrs)

      new_number = "321321321"
      changeset = %Phone{}
      |> Phone.changeset(Map.put(attrs, :number, new_number))

      assert {:ok, %Phone{country_code: country_code, number: number}} = Repo.insert(changeset)
      assert number == new_number
      assert country_code == attrs[:country_code]

      new_country_code = "+7"
      changeset = %Phone{}
      |> Phone.changeset(Map.put(attrs, :country_code, new_country_code))

      assert {:ok, %Phone{country_code: country_code, number: number}} = Repo.insert(changeset)
      assert number == attrs[:number]
      assert country_code == new_country_code
  end

  test "changeset must validate country_code" do

  end
end
