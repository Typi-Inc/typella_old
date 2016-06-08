defmodule Typi.MessageTest do
  use Typi.ModelCase

  # alias Typi.Message

  @valid_attrs %{body: "some content", future_date_time: %{day: 17, hour: 14, min: 0, month: 4, sec: 0, year: 2010}}
  @invalid_attrs %{}

  # test "changeset with valid attributes" do
  #   changeset = Message.changeset(%Message{}, @valid_attrs)
  #   assert changeset.valid?
  # end
  #
  # test "changeset with invalid attributes" do
  #   changeset = Message.changeset(%Message{}, @invalid_attrs)
  #   refute changeset.valid?
  # end
end
