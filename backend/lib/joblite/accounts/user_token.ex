defmodule Joblite.Accounts.UserToken do
  @moduledoc """
  A stored session-token hash. The raw token is returned exactly once when
  generated and is never persisted or logged; only its SHA-256 hash is stored.
  A token is valid until `@session_validity_in_days` after `inserted_at`.
  """

  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, warn: false

  alias Joblite.Accounts.User

  @primary_key {:id, :binary_id, autogenerate: true}
  @type t :: %__MODULE__{}

  @hash_algorithm :sha256
  @rand_size 32
  @session_validity_in_days 60
  @session_context "session"

  schema "users_tokens" do
    field(:token, :binary)
    field(:context, :string)
    belongs_to(:user, User, type: :binary_id)

    timestamps(updated_at: false, type: :utc_datetime)
  end

  @doc "Builds a token struct (storing the hash) plus the raw value to hand to the caller once."
  @spec build_session_token(User.t()) :: {binary(), t()}
  def build_session_token(%User{id: user_id}) do
    raw_token = :crypto.strong_rand_bytes(@rand_size)

    {raw_token,
     %__MODULE__{user_id: user_id, context: @session_context, token: hash_token(raw_token)}}
  end

  @doc "Query returning the user for a valid, unexpired session token, or nil."
  @spec verify_session_token_query(binary()) :: Ecto.Query.t()
  def verify_session_token_query(raw_token) when is_binary(raw_token) do
    hashed = hash_token(raw_token)
    earliest = DateTime.add(DateTime.utc_now(), -@session_validity_in_days, :day)

    from(token in __MODULE__,
      where:
        token.token == ^hashed and
          token.context == ^@session_context and
          token.inserted_at > ^earliest,
      join: user in assoc(token, :user),
      select: user
    )
  end

  @doc "Deletes every stored hash for the given raw session token."
  @spec delete_session_token_query(binary()) :: Ecto.Query.t()
  def delete_session_token_query(raw_token) when is_binary(raw_token) do
    hashed = hash_token(raw_token)

    from(token in __MODULE__,
      where: token.token == ^hashed and token.context == ^@session_context
    )
  end

  @doc "SHA-256 hash of a raw token; the only form ever stored."
  @spec hash_token(binary()) :: binary()
  def hash_token(raw_token) when is_binary(raw_token) do
    :crypto.hash(@hash_algorithm, raw_token)
  end

  def changeset(token, attrs) do
    cast(token, attrs, [:token, :context])
  end
end
