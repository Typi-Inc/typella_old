defmodule Typi.Email do
  use Typi.Web, :model

  schema "emails" do
    field :email_id, :string
    field :value, :string
    belongs_to :contact, Typi.User
    belongs_to :user, Typi.User

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:email_id, :value])
    |> validate_required([:email_id, :value])
  end
end
