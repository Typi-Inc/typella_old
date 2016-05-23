defmodule Typi.Registration do
  use Typi.Web, :model

  schema "registrations" do
    field :country_code, :string
    field :number, :string
    field :region, :string
    field :uuid, :string
    field :otp, :string, virtual: true
    field :otp_hash, :string

    timestamps
  end

  # only used for input validation
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:country_code, :number, :region, :uuid, :otp])
    |> validate_required([:country_code, :number, :region, :uuid, :otp])
    |> validate_length(:otp, min: 4, max: 4)
    |> Typi.Phone.validate_phone
    |> Typi.Device.validate_uuid
    |> put_otp_hash
  end

  def put_otp_hash(changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true, changes: %{otp: otp}} ->
        put_change(changeset, :otp_hash, Comeonin.Bcrypt.hashpwsalt(otp))
      _ ->
        changeset
    end
  end

  def to_user(registration) do
    %Typi.User{
      devices: [struct(Typi.Device, Map.from_struct(registration))],
      phones: [struct(Typi.Phone, Map.from_struct(registration))]
    }
  end
end
