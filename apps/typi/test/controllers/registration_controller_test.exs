defmodule Typi.RegistrationControllerTest do
  use Typi.ConnCase, async: true
  import Mock
  alias Typi.{Device, Phone, Registration, User}

  @register_attrs %{"country_code": "+1", "region": "US",
    "number": "7012530000", "uuid": "599F9C00-92DC-4B5C-9464-7971F01F8370"}
  @verify_attrs %{"country_code": "+1", "number": "7012530000", "code": "1234"}

  setup %{conn: conn} do
    {:ok, %{conn: put_req_header(conn, "accept", "application/json")}}
  end

  test "/register receives params and generates otp, hashes it and stores in db", %{conn: conn} do
    with_mock Typi.OTP.InMemory, [generate_otp: fn -> "1234" end] do
      conn = post conn, registration_path(conn, :register), registration: @register_attrs
      assert json_response(conn, 201)
      assert user = Repo.get_by(Registration, @register_attrs)
      refute user.otp
      assert called Typi.OTP.InMemory.generate_otp
      assert Comeonin.Bcrypt.checkpw("1234", user.otp_hash)
    end
  end

  test "/register sends error if country code is not of approproate format", %{conn: conn} do
    conn = post conn, registration_path(conn, :register),
      registration: Map.put(@register_attrs, "country_code", "123123123")
    assert json_response(conn, 422) == %{"errors" => %{"number" => ["invalid phone number"]}}
  end

  test "/register sends error if number is not of appropriate format", %{conn: conn} do
    conn = post conn, registration_path(conn, :register),
      registration: Map.put(@register_attrs, "number", "123123123123123123123")
    assert json_response(conn, 422) == %{"errors" => %{"number" => ["invalid phone number"]}}
    refute Repo.get_by(Registration, @register_attrs)
  end

  test "/register sends error if regions is not of appropriate format", %{conn: conn} do
    conn = post conn, registration_path(conn, :register),
      registration: Map.put(@register_attrs, "region", "ADSD")
    assert json_response(conn, 422) == %{"errors" => %{"region" => ["should be at most 3 character(s)"]}}
    refute Repo.get_by(Registration, @register_attrs)
  end

  test "/register sends error if uuid is not of appropriate format", %{conn: conn} do
    conn = post conn, registration_path(conn, :register),
      registration: Map.put(@register_attrs, "uuid", "ADSD")
    assert json_response(conn, 422) == %{"errors" => %{"uuid" => ["has invalid format"]}}
    refute Repo.get_by(Registration, @register_attrs)
  end

  test "/register sends sms via twilio if params are valid", %{conn: conn} do
    with_mock Typi.ExTwilio.InMemory.Message, [create: fn([to: to, from: _from, body: body]) ->
      assert to == @register_attrs.country_code <> @register_attrs.number
      assert body == "1234"
    end] do
      conn = post conn, registration_path(conn, :register), registration: @register_attrs
      assert json_response(conn, 201)
      # TODO find out what happens should be the same as first test
      # assert called Typi.ExTwilio.InMemory.Message.create
    end
  end

  test "/verify receives registration_id and otp, checks with otp_hash and stores user in db", %{conn: conn} do
    insert_registration(@register_attrs)
    conn = post conn, registration_path(conn, :verify),
      registration: @verify_attrs
    assert json_response(conn, 201)["jwt"]

    assert Repo.get_by(Phone, Map.take(@register_attrs, [:country_code, :number, :region]))
    assert Repo.get_by(Device, Map.take(@register_attrs, [:uuid]))
    assert Repo.all from u in User,
      join: d in assoc(u, :devices),
      where: d.uuid == ^@register_attrs.uuid
  end

  test "/verify responds with error if incorrect country_code/number is passed", %{conn: conn} do
    insert_registration(@register_attrs)
    conn = post conn, registration_path(conn, :verify),
      registration: Map.put(@verify_attrs, "country_code", "+7")
    assert json_response(conn, 422) == %{"errors" => %{"registration" => "not yet registered"}}

    refute Repo.get_by(Phone, Map.take(@register_attrs, [:country_code, :number, :region]))
    refute Repo.get_by(Device, Map.take(@register_attrs, [:uuid]))
    assert [] = Repo.all from u in User,
      join: d in assoc(u, :devices),
      where: d.uuid == ^@register_attrs.uuid
  end

  test "/verify responds with error if incorrect otp is passed", %{conn: conn} do
    insert_registration(@register_attrs)
    conn = post conn, registration_path(conn, :verify),
      registration: Map.put(@verify_attrs, "code", "2345")
    assert json_response(conn, 422) == %{"errors" => %{"code" => "not valid"}}

    refute Repo.get_by(Phone, Map.take(@register_attrs, [:country_code, :number, :region]))
    refute Repo.get_by(Device, Map.take(@register_attrs, [:uuid]))
    assert [] = Repo.all from u in User,
      join: d in assoc(u, :devices),
      where: d.uuid == ^@register_attrs.uuid
  end

  test "/verify responds with error if otp is expired", %{conn: conn} do
    insert_registration(Map.put(@register_attrs, :inserted_at, %Ecto.DateTime{
      year: 2015, month: 4, day: 27, hour: 10, min: 8, sec: 42, usec: 0
    }))
    conn = post conn, registration_path(conn, :verify), registration: @verify_attrs
    assert json_response(conn, 422) == %{"errors" => %{"code" => "already expired"}}

    refute Repo.get_by(Phone, Map.take(@register_attrs, [:country_code, :number, :region]))
    refute Repo.get_by(Device, Map.take(@register_attrs, [:uuid]))
    assert [] = Repo.all from u in User,
      join: d in assoc(u, :devices),
      where: d.uuid == ^@register_attrs.uuid
  end

  test "/verify if user with device and phone already exists just sends token", %{conn: conn} do
    insert_user(%User{
      devices: [struct(Device, @register_attrs)],
      phones: [struct(Phone, @register_attrs)]
    })
    insert_registration(@register_attrs)
    conn = post conn, registration_path(conn, :verify), registration: @verify_attrs
    assert json_response(conn, 201)["jwt"]

    assert [_device] = Repo.all from d in Device, where: d.uuid == ^@register_attrs.uuid
    assert [_phone] = Repo.all from p in Phone,
      where: p.country_code == ^@register_attrs.country_code and p.number == ^@register_attrs.number

    assert [user] = Repo.all from u in User,
      join: d in assoc(u, :devices),
      join: p in assoc(u, :phones),
      where: d.uuid == ^@register_attrs.uuid or
        (p.country_code == ^@register_attrs.country_code and p.number == ^@register_attrs.number),
      preload: [devices: d, phones: p]
    assert length(user.devices) == 1
    assert length(user.phones) == 1
  end

  test "/verify if user with device but not phone already exists appends phone and sends token", %{conn: conn} do
    attrs = Map.merge(@register_attrs, %{country_code: "+7", number: "7013812312", region: "KZ"})
    insert_user(%User{
      devices: [struct(Device, attrs)],
      phones: [struct(Phone, attrs)]
    })
    insert_registration(@register_attrs)
    conn = post conn, registration_path(conn, :verify), registration: @verify_attrs
    assert json_response(conn, 201)["jwt"]

    assert [_device] = Repo.all from d in Device, where: d.uuid == ^@register_attrs.uuid
    assert [_phone] = Repo.all from p in Phone,
      where: p.country_code == ^@register_attrs.country_code and p.number == ^@register_attrs.number

    assert [user] = Repo.all from u in User,
      join: d in assoc(u, :devices),
      join: p in assoc(u, :phones),
      where: d.uuid == ^@register_attrs.uuid or
        (p.country_code == ^@register_attrs.country_code and p.number == ^@register_attrs.number),
      preload: [devices: d, phones: p]
    assert length(user.devices) == 1
    assert length(user.phones) == 2
  end

  test "/verify if user with phone but not device already exists appends device and sends token", %{conn: conn} do
    attrs = Map.merge(@register_attrs, %{uuid: "132F9C00-92DC-4B5C-9464-7971F01F8370"})
    insert_user(%User{
      devices: [struct(Device, attrs)],
      phones: [struct(Phone, attrs)]
    })
    insert_registration(@register_attrs)
    conn = post conn, registration_path(conn, :verify), registration: @verify_attrs
    assert json_response(conn, 201)["jwt"]

    assert [_device] = Repo.all from d in Device, where: d.uuid == ^@register_attrs.uuid
    assert [_phone] = Repo.all from p in Phone,
      where: p.country_code == ^@register_attrs.country_code and p.number == ^@register_attrs.number

    assert [user] = Repo.all from u in User,
      join: d in assoc(u, :devices),
      join: p in assoc(u, :phones),
      where: d.uuid == ^@register_attrs.uuid or
        (p.country_code == ^@register_attrs.country_code and p.number == ^@register_attrs.number),
      preload: [devices: d, phones: p]
    assert length(user.devices) == 2
    assert length(user.phones) == 1
  end

  test "/verify deletes registration if user was successfully created", %{conn: conn} do
    attrs = Map.merge(@register_attrs, %{uuid: "132F9C00-92DC-4B5C-9464-7971F01F8370"})
    insert_user(%User{
      devices: [struct(Device, attrs)],
      phones: [struct(Phone, attrs)]
    })
    registration = insert_registration(@register_attrs)
    conn = post conn, registration_path(conn, :verify), registration: @verify_attrs
    assert json_response(conn, 201)["jwt"]

    assert [_device] = Repo.all from d in Device, where: d.uuid == ^@register_attrs.uuid
    assert [_phone] = Repo.all from p in Phone,
      where: p.country_code == ^@register_attrs.country_code and p.number == ^@register_attrs.number

    assert [user] = Repo.all from u in User,
      join: d in assoc(u, :devices),
      join: p in assoc(u, :phones),
      where: d.uuid == ^@register_attrs.uuid or
        (p.country_code == ^@register_attrs.country_code and p.number == ^@register_attrs.number),
      preload: [devices: d, phones: p]
    assert length(user.devices) == 2
    assert length(user.phones) == 1
    refute Repo.get(Registration, registration.id)
  end
end
