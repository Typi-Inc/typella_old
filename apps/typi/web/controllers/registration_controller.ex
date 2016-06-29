defmodule Typi.RegistrationController do
  use Typi.Web, :controller
  alias Typi.{Registration, User}
  require Logger

  @otp_expiration 3600
  @otp Application.get_env(:typi, :otp)
  @twilio_api Application.get_env(:typi, :twilio_api)
  @twilio_phone_number Application.get_env(:ex_twilio, :phone_number)

  plug :scrub_params, "registration" when action in [:register]
  plug :scrub_params, "verification" when action in [:verify]

  def register(conn, %{"registration" => %{"country_code" => _, "number" => _, "uuid" => _} = registration_params}) do
    otp = @otp.generate_otp
    IO.inspect otp
    registration_params
    |> Map.take([:country_code, :number, :uuid])
    |> get_registration
    |> update_or_insert_registration(registration_params, otp)
    |> case do
      {:ok, _registration} ->
        send_otp(registration_params, otp)
        conn
        |> put_status(:ok)
        |> json(%{})
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(Typi.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def verify(conn, %{"verification" => %{"country_code" => country_code, "number" => number, "code" => otp} = verification}) do
    with {:ok, registration} <- get_registration(country_code, number),
      {:ok, _registration} <- validate_otp(registration, otp),
      {:ok, user} <- update_or_insert_user(registration),
      {:ok, jwt, _full_claims} = encode_and_sign(user),
      {:ok, _registration} = Repo.delete(registration)
    do
      {:ok, jwt, user}
    end
    |> case do
      {:ok, jwt, user} ->
        conn
        |> put_status(:created)
        |> json(%{jwt: jwt, id: user.id})
        # |> render("verified.json", jwt: jwt, user: user)
      {:error, reasons} ->
        conn
        |> put_status(:unprocessable_entity)
        |> return_error(reasons)
    end
  end

  defp get_registration(attrs) do
    Repo.get_by(Registration, attrs)
  end

  defp update_or_insert_registration(nil, params, otp) do
    changeset =
      %Registration{}
      |> Registration.changeset(Map.put(params, "otp", otp))
    Repo.insert(changeset)
  end

  defp update_or_insert_registration(registration, _params, otp) do
    registration
    |> Ecto.Changeset.change
    |> Ecto.Changeset.put_change(:otp, otp)
    |> Registration.put_otp_hash
    |> Repo.update
  end

  defp send_otp(%{"country_code" => country_code, "number" => number}, otp) do
    @twilio_api.Message.create([
      to: country_code <> number,
      from: @twilio_phone_number,
      body: otp
    ])
  end

  defp return_error(conn, reasons) do
    if Map.has_key?(reasons, :__struct__) and reasons.__struct__ == Ecto.Changeset do
      conn
      |> render(Typi.ChangesetView, "error.json", changeset: reasons)
    else
      conn
      |> json(reasons)
    end
  end

  defp get_registration(country_code, number) do
    case Repo.get_by(Registration, %{country_code: country_code, number: number}) do
      nil -> {:error, %{"errors" => %{"verification" => "not yet registered"}}}
      registration -> {:ok, registration}
    end
  end

  defp validate_otp(registration, otp) do
    if Comeonin.Bcrypt.checkpw(otp, registration.otp_hash) do
      registration
      |> to_expiration_datetime
      |> Ecto.DateTime.compare(Ecto.DateTime.utc)
      |> case do
        :gt -> {:ok, registration}
        _ -> {:error, %{"errors" => %{"code" => "already expired"}}}
      end
    else
      {:error, %{"errors" => %{"code" => "not valid"}}}
    end
  end

  defp update_or_insert_user(registration) do
    query = from u in User,
      join: d in assoc(u, :devices),
      join: p in assoc(u, :phones),
      where: d.uuid == ^registration.uuid or
        (p.country_code == ^registration.country_code and p.number == ^registration.number),
      preload: [devices: d, phones: p]

    case Repo.all(query) do
      [user] -> update_if_needed(user, registration)
      [] -> Repo.insert(Registration.to_user(registration))
      _ ->
        Logger.error "the following registration appears to have more then one " <>
          "corresponding user #{inspect registration}"
        {:error, %{"errors" => %{"verification" => "server error please contact us"}}}
    end
  end

  defp encode_and_sign(user) do
    Guardian.encode_and_sign(user, :token)
  end

  defp to_expiration_datetime(registration) do
    registration.inserted_at
    |> Ecto.DateTime.to_erl
    |> :calendar.datetime_to_gregorian_seconds
    |> Kernel.+(@otp_expiration)
    |> :calendar.gregorian_seconds_to_datetime
    |> Ecto.DateTime.from_erl
  end

  defp update_if_needed(user, registration) do
    case {has_device(user, registration), has_phone(user, registration)} do
      {true, true} -> {:ok, user}
      {true, false} -> add_assoc(user, :phones, Registration.to_phone(registration))
      {false, true} -> add_assoc(user, :devices, Registration.to_device(registration))
      _ ->
        Logger.error "The following user seems to have have either device or phone " <>
        "from the following registration, however in reality has " <>
        "does not have both/n#{inspect user}/n#{inspect registration}"
    end
  end

  defp has_device(user, registration) do
    Enum.filter(user.devices, fn device ->
      device.uuid == registration.uuid
    end)
    |> case do
      [] -> false
      _ -> true
    end
  end

  defp has_phone(user, registration) do
    Enum.filter(user.phones, fn phone ->
      phone.country_code == registration.country_code and
      phone.number == registration.number
    end)
    |> case do
      [] -> false
      _ -> true
    end
  end

  defp add_assoc(user, assoc, entity) do
    children_changesets =
      [entity | Map.get(user, assoc)]
      |> Enum.map(&Ecto.Changeset.change/1)

    user
    |> Ecto.Changeset.change
    |> Ecto.Changeset.put_assoc(assoc, children_changesets)
    |> Repo.update
  end
end
