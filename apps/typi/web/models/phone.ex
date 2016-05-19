defmodule Typi.Phone do
  use Typi.Web, :model

  schema "phones" do
    field :country_code, :string
    field :number, :string
    belongs_to :user, Typi.User

    timestamps
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:country_code, :number])
    |> validate_required([:country_code, :number])
    |> unique_constraint(:number, name: :phones_country_code_number_index)
  end
end
