defmodule Typi.User do
  use Typi.Web, :model

  schema "users" do
    field :name, :string
    field :profile_pic, :string
    has_many :phones, Typi.Phone
    has_many :devices, Typi.Device

    timestamps
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:name, :profile_pic])
    |> validate_required([])
  end
end
