defmodule Typi.ChatUser do
  use Typi.Web, :model

  schema "chats_users" do
    field :is_admin, :boolean, default: false
    belongs_to :chat, Typi.Chat
    belongs_to :user, Typi.User

    timestamps
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:is_admin])
    |> validate_required([:is_admin])
  end
end
