defmodule Typi.Contact do
  use Typi.Web, :model

  schema "contacts" do
    field :contact_id, :string
    field :name, :string
    belongs_to :phones, Typi.Phones
    belongs_to :emails, Typi.Emails

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:contact_id, :name])
    |> validate_required([:contact_id, :name])
  end
end
