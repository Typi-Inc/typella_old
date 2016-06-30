defmodule Typi.EmailTest do
  use Typi.ModelCase

  alias Typi.Email

  @valid_attrs %{email_id: "some content", value: "some content"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Email.changeset(%Email{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Email.changeset(%Email{}, @invalid_attrs)
    refute changeset.valid?
  end
end
