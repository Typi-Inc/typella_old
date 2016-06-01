defmodule Typi.Message do
  use Typi.Web, :model

  schema "messages" do
    field :client_id, :integer
    field :body, :string
    field :status, :string
    field :future_datetime, Ecto.DateTime
    field :created_at, Ecto.DateTime
    belongs_to :sender, Typi.User
    belongs_to :chat, Typi.Chat

    timestamps
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:client_id, :body])
    |> validate_required([:client_id, :body])
    |> cast_string_to_datetime(params, :created_at)
    |> cast_string_to_datetime(params, :future_datetime)
  end

  defp cast_string_to_datetime(changeset, params, to_cast) do
    key = to_cast |> to_string
    if Map.has_key?(params, key) do
      case Ecto.DateTime.cast(params[key]) do
        {:ok, datetime} ->
          put_change(changeset, to_cast, datetime)
        _ ->
          add_error(changeset, to_cast, "datetime is not of appropriate format")
      end
    else
      changeset
    end
  end
end
