defmodule Typi.UserControllerTest do
  use Typi.ConnCase, async: true

  @valid_attrs %{"country_code": "+1", "region": "US", "number": "7012530000", "idfv": "599F9C00-92DC-4B5C-9464-7971F01F8370"}

  setup %{conn: conn} do
    {:ok, %{conn: bypass_through(Typi.Router, :api)}}
  end
  #
  # test "registers new user with country_code, region, number and uuid of the device" do
  #   conn = post conn, user_path(conn, :register), user: @valid_attrs
  # end
end
