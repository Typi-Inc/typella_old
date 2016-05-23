defmodule Typi.RegistrationController do
  use Typi.Web, :controller
  alias Typi.Registration

  @otp Application.get_env(:typi, :otp)
  @twilio_api Application.get_env(:typi, :twilio_api)
  @twilio_phone_number Application.get_env(:ex_twilio, :phone_number)

  plug :scrub_params, "registration" when action in [:register]

  def register(conn, %{"registration" => registration_params}) do
    otp = @otp.generate_otp()
    changeset =
      %Registration{}
      |> Registration.changeset(Map.put(registration_params, "otp", otp))

    case Repo.insert(changeset) do
      {:ok, registration} ->
        send_otp(registration_params, otp)
        conn
        |> put_status(:created)
        |> json(%{registration_id: registration.id})
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(Typi.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def send_otp(%{"country_code" => country_code, "number" => number}, otp) do
    @twilio_api.Message.create([
      to: country_code <> number,
      from: @twilio_phone_number,
      body: otp
    ])
  end
end
