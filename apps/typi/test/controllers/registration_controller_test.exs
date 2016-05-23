defmodule Typi.RegistrationControllerTest do
  use Typi.ConnCase, async: true
  import Mock
  alias Typi.{Device, Phone, Registration, User}

  @valid_attrs %{"country_code": "+1", "region": "US",
    "number": "7012530000", "uuid": "599F9C00-92DC-4B5C-9464-7971F01F8370"}

  setup %{conn: conn} do
    {:ok, %{conn: put_req_header(conn, "accept", "application/json")}}
  end

  test "/register receives params and generates otp, hashes it and stores in db", %{conn: conn} do
    with_mock Typi.OTP.InMemory, [generate_otp: fn -> "1234" end] do
      conn = post conn, registration_path(conn, :register), registration: @valid_attrs
      assert json_response(conn, 201)["registration_id"]
      assert user = Repo.get_by(Registration, @valid_attrs)
      refute user.otp
      assert called Typi.OTP.InMemory.generate_otp
      assert Comeonin.Bcrypt.checkpw("1234", user.otp_hash)
    end
  end

  test "/register sends error if country code is not of approproate format", %{conn: conn} do
    conn = post conn, registration_path(conn, :register),
      registration: Map.put(@valid_attrs, "country_code", "123123123")
    assert json_response(conn, 422) == %{"errors" => %{"number" => ["invalid phone number"]}}
  end

  test "/register sends error if number is not of appropriate format", %{conn: conn} do
    conn = post conn, registration_path(conn, :register),
      registration: Map.put(@valid_attrs, "number", "123123123123123123123")
    assert json_response(conn, 422) == %{"errors" => %{"number" => ["invalid phone number"]}}
  end

  test "/register sends error if regions is not of appropriate format", %{conn: conn} do
    conn = post conn, registration_path(conn, :register),
      registration: Map.put(@valid_attrs, "region", "ADSD")
    assert json_response(conn, 422) == %{"errors" => %{"region" => ["should be at most 3 character(s)"]}}
  end

  test "/register sends error if uuid is not of appropriate format", %{conn: conn} do
    conn = post conn, registration_path(conn, :register),
      registration: Map.put(@valid_attrs, "uuid", "ADSD")
    assert json_response(conn, 422) == %{"errors" => %{"uuid" => ["has invalid format"]}}
  end

  test "/register sends sms via twilio if params are valid", %{conn: conn} do
    with_mock Typi.ExTwilio.InMemory.Message, [create: fn([to: to, from: from, body: body]) ->
      assert to == @valid_attrs.country_code <> @valid_attrs.number
      assert body == "1234"
    end] do
      conn = post conn, registration_path(conn, :register), registration: @valid_attrs
      assert json_response(conn, 201)["registration_id"]
      # TODO find out what happens should be the same as first test
      # assert called Typi.ExTwilio.InMemory.Message.create
    end
  end

  # test "registers new user with country_code, region, number and uuid of the device", %{conn: conn} do
  #   conn = post conn, registration_path(conn, :register), user: @valid_attrs
  #   assert json_response(conn, 201)["user_id"]
  #   assert Repo.get_by(Phone, Map.take(@valid_attrs, [:country_code, :region, :number]))
  #   assert Repo.get_by(Device, Map.take(@valid_attrs, [:uuid]))
  # end
  #
  # test "if user already exists with given phone, registers new device" do
  #   user = insert_user(%User{
  #     devices: [struct(Device, Map.put(@valid_attrs, :uuid, "699F9C00-92DC-4B5C-9464-7971F01F8370"))],
  #     phones: [struct(Phone, @valid_attrs)]
  #   })
  #
  #   conn = post conn, registration_path(conn, :register), user: @valid_attrs
  #   assert json_response(conn, 201)["user_id"] == user.id
  # end
  #
  # test "if user already exists with given device, registers new phone" do
  #
  # end
  #
  # test "after registering user generates OTP and sends it via twilio" do
  #   conn = post conn, registration_path(conn, :register), user: @valid_attrs
  #   assert json_response(conn, 201)["user_id"]
  # end
end
