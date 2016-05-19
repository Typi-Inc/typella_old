defmodule Typi.UserTest do
  use Typi.ModelCase

  alias Typi.User

  @valid_attrs %{name: "some content", profile_pic: "some content"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = User.changeset(%User{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = User.changeset(%User{}, @invalid_attrs)
    refute changeset.valid?
  end
end
