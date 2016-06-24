defmodule Typi.Message do
  use Typi.Web, :model
  use Typi.Database

  embedded_schema do
    field :body, :string
    field :chat_id, :integer
    field :created_at, :integer
    field :publish_at, :integer
    field :status, :string
    field :user_id, :integer
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:body, :chat_id, :created_at, :publish_at, :status, :user_id])
    |> validate_required([:body, :created_at])
  end

  def to_amnesia_message(struct) do
    map =
      struct
      |> Map.from_struct
    struct(Message, map)
  end
end
