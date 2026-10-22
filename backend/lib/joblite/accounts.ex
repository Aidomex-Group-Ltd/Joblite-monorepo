defmodule Joblite.Accounts do
  @moduledoc """
  Public boundary for account identity and session-token lifecycle.

  Email is the identity. Accounts may start passwordless: a six-digit one-time
  code is emailed, and consuming it both signs the account in and confirms the
  address. Session tokens are generated as opaque random values, stored only as
  hashes and accepted until they expire or are revoked. All persistence goes
  through the single core Repo; no web or LiveView dependency exists here.
  """

  import Ecto.Query, warn: false

  alias Joblite.Accounts.{LoginCode, User, UserToken}
  alias Joblite.Repo

  @doc "Looks up a user by email, normalizing case. Returns nil when absent."
  @spec get_user_by_email(String.t()) :: User.t() | nil
  def get_user_by_email(email) when is_binary(email) do
    Repo.get_by(User, email: String.downcase(email))
  end

  @doc "Fetches a user by id, or nil when the account no longer exists."
  @spec get_user(String.t()) :: User.t() | nil
  def get_user(id) when is_binary(id), do: Repo.get(User, id)

  @doc "Fetches a user by id or raises."
  @spec get_user!(String.t()) :: User.t()
  def get_user!(id), do: Repo.get!(User, id)

  @doc """
  Starts a passwordless signup. Known emails are returned as `:existing` so the
  caller can send a sign-in code without revealing whether the account existed.
  A new account stores the chosen name and role but no password.
  """
  @spec start_passwordless_signup(map()) ::
          {:ok, User.t(), :new | :existing} | {:error, Ecto.Changeset.t()}
  def start_passwordless_signup(attrs) when is_map(attrs) do
    email = attrs[:email] || attrs["email"] || ""

    case get_user_by_email(email) do
      %User{} = user -> {:ok, user, :existing}
      nil -> insert_passwordless_user(attrs, email)
    end
  end

  defp insert_passwordless_user(attrs, email) do
    %User{}
    |> User.passwordless_registration_changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, user} ->
        {:ok, user, :new}

      {:error, changeset} ->
        case get_user_by_email(email) do
          %User{} = user -> {:ok, user, :existing}
          nil -> {:error, changeset}
        end
    end
  end

  @doc """
  Issues a sign-in code for a known email. Unknown emails return
  `{:ok, :ignored}` so callers can respond identically without enumerating
  accounts.
  """
  @spec issue_login_code(String.t()) ::
          {:ok, :ignored | {:issued, User.t(), String.t()}}
          | {:error, {:rate_limited, pos_integer()}}
  def issue_login_code(email) when is_binary(email) do
    case get_user_by_email(email) do
      nil ->
        Bcrypt.no_user_verify()
        {:ok, :ignored}

      %User{} = user ->
        case LoginCode.issue(user) do
          {:ok, code} -> {:ok, {:issued, user, code}}
          {:error, reason} -> {:error, reason}
        end
    end
  end

  @doc "Consumes a sign-in code and returns the confirmed account."
  @spec verify_login_code(User.t(), term()) :: {:ok, User.t()} | {:error, :invalid_code}
  def verify_login_code(%User{} = user, code), do: LoginCode.verify(user, code)

  @doc "Cancels unused sign-in codes, for example when delivery fails."
  @spec revoke_login_codes(User.t()) :: :ok
  def revoke_login_codes(%User{} = user), do: LoginCode.revoke(user)

  @doc "Registers a user from email and password."
  @spec register_user(map()) :: {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  def register_user(attrs) do
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
  end

  @doc "Changeset for registration forms (create or update)."
  @spec change_user_registration(User.t(), map()) :: Ecto.Changeset.t()
  def change_user_registration(%User{} = user, attrs \\ %{}) do
    User.registration_changeset(user, attrs)
  end

  @doc """
  Authenticates by email and password. Returns `{:error, :invalid_credentials}`
  for both unknown emails and wrong passwords; the unknown-email path still
  performs a dummy bcrypt verify so the two failure modes take comparable time.
  """
  @spec authenticate_by_email_password(String.t(), String.t()) ::
          {:ok, User.t()} | {:error, :invalid_credentials}
  def authenticate_by_email_password(email, password)
      when is_binary(email) and is_binary(password) do
    case get_user_by_email(email) do
      %User{hashed_password: hashed} = user when is_binary(hashed) ->
        if Bcrypt.verify_pass(password, hashed) do
          {:ok, user}
        else
          {:error, :invalid_credentials}
        end

      %User{} ->
        Bcrypt.no_user_verify()
        {:error, :invalid_credentials}

      nil ->
        Bcrypt.no_user_verify()
        {:error, :invalid_credentials}
    end
  end

  @doc "Generates a session token for the user. The raw token is returned once; only its hash is stored."
  @spec generate_user_session_token(User.t()) :: binary()
  def generate_user_session_token(%User{} = user) do
    {raw_token, token_struct} = UserToken.build_session_token(user)
    {:ok, _stored} = Repo.insert(token_struct)
    raw_token
  end

  @doc "Returns the user for a valid unexpired session token, or nil for unknown, revoked or expired tokens."
  @spec get_user_by_session_token(binary()) :: User.t() | nil
  def get_user_by_session_token(raw_token) when is_binary(raw_token) do
    Repo.one(UserToken.verify_session_token_query(raw_token))
  end

  @doc "Revokes a session token by deleting its stored hash. Idempotent."
  @spec delete_user_session_token(binary()) :: :ok
  def delete_user_session_token(raw_token) when is_binary(raw_token) do
    {_count, _} = Repo.delete_all(UserToken.delete_session_token_query(raw_token))
    :ok
  end
end
