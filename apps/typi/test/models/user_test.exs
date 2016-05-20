defmodule Typi.UserTest do
  use Typi.ModelCase, async: true

  alias Typi.User

  @valid_attrs %{name: "some content", profile_pic: "some content"}

  test "changeset with valid attributes" do
    changeset = User.changeset(%User{}, @valid_attrs)
    assert changeset.valid?
  end
end
