defmodule Typi.Registration do
  use Typi.Web, :model

  embedded_schema do
    field :country_code
    field :number
    field :region
    field :uuid
  end

  # only used for input validation
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:country_code, :number, :region, :uuid])
    |> validate_required([:country_code, :number, :region, :uuid])
    |> Typi.Phone.validate_phone
  end

  def to_user(registration) do
    %Typi.User{
      devices: [struct(Typi.Device, Map.from_struct(registration))],
      phones: [struct(Typi.Phone, Map.from_struct(registration))]
    }
  end
end
