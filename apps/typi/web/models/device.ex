defmodule Typi.Device do
  use Typi.Web, :model

  schema "devices" do
    field :uuid, :string
    belongs_to :user, Typi.User

    timestamps
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  # TODO Do I need to hash device's uuid?
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:uuid, :user_id])
    |> validate_required([:uuid, :user_id])
    |> validate_uuid
    |> unique_constraint(:uuid)
    |> assoc_constraint(:user)
  end

  def validate_uuid(changeset) do
    changeset
    |> validate_format(:uuid, ~r/[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}/)
  end
end
