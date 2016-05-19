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
    |> cast(params, [:uuid])
    |> validate_required([:uuid])
    |> unique_constraint(:uuid)
  end
end
