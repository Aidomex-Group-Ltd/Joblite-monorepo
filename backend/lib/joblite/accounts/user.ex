defmodule Joblite.Accounts.User do
  @moduledoc """
  A registered account. Email is the unique identity, normalized to lowercase.
  Passwordless accounts sign in with an emailed one-time code; an optional
  password remains available for compatibility and is stored only as a bcrypt
  hash. The name and role describe how the account uses Joblite.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @type t :: %__MODULE__{}

  @email_regex ~r/^[^\s]+@[^\s]+\.[^\s]+$/
  @roles ~w(candidate employer)

  schema "users" do
    field(:email, :string)
    field(:name, :string)
    field(:role, :string, default: "candidate")
    field(:password, :string, virtual: true, redact: true)
    field(:hashed_password, :string, redact: true)
    field(:confirmed_at, :utc_datetime)

    timestamps(type: :utc_datetime)
  end

  def registration_changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :name, :role, :password])
    |> validate_email()
    |> validate_name()
    |> validate_role()
    |> validate_password()
    |> put_hashed_password()
    |> unique_constraint(:email)
  end

  def passwordless_registration_changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :name, :role])
    |> validate_email()
    |> validate_required([:name])
    |> validate_length(:name, min: 1, max: 80)
    |> validate_role()
    |> unique_constraint(:email)
  end

  def confirm_changeset(user) do
    user
    |> change(confirmed_at: DateTime.utc_now() |> DateTime.truncate(:second))
  end

  defp validate_email(changeset) do
    changeset
    |> validate_required([:email])
    |> validate_format(:email, @email_regex)
    |> validate_length(:email, max: 160)
    |> update_change(:email, &String.downcase/1)
  end

  defp validate_name(changeset) do
    changeset
    |> validate_length(:name, max: 80)
  end

  defp validate_role(changeset) do
    validate_inclusion(changeset, :role, @roles)
  end

  defp validate_password(changeset) do
    changeset
    |> validate_required([:password])
    |> validate_length(:password, min: 8, max: 72)
  end

  defp put_hashed_password(
         %Ecto.Changeset{valid?: true, changes: %{password: password}} = changeset
       ) do
    put_change(changeset, :hashed_password, Bcrypt.hash_pwd_salt(password))
  end

  defp put_hashed_password(changeset), do: changeset

  @doc "The roles an account may choose."
  @spec roles() :: [String.t()]
  def roles, do: @roles
end
