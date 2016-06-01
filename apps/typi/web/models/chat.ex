defmodule Typi.Chat do
  use Typi.Web, :model

  schema "chats" do
    has_many :messages, Typi.Message
    many_to_many :users, Typi.User,
      join_through: Typi.ChatUser,
      on_replace: :delete

    timestamps
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [])
    |> validate_required([])
  end
end
