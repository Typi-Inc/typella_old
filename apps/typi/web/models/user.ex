defmodule Typi.User do
  use Typi.Web, :model

  schema "users" do
    field :name, :string
    field :profile_pic, :string
    has_many :devices, Typi.Device
    has_many :contacts, Typi.Contact
    has_many :phones, Typi.Phone
    many_to_many :chats, Typi.Chat,
      join_through: Typi.ChatUser,
      on_replace: :delete
    timestamps
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:name, :profile_pic])
    |> cast_assoc(:devices)
    |> cast_assoc(:phones)
    |> validate_required([])
  end
end
