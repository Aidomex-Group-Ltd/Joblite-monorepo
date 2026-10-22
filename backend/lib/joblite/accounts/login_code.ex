defmodule Joblite.Accounts.LoginCode do
  @moduledoc """
  A one-time sign-in code sent by email.

  Only a SHA-256 hash of the six-digit code is stored. A code expires after
  fifteen minutes, accepts five attempts and is consumed exactly once. New
  codes replace the unused code of the same account; at most five codes may
  be issued in an hour.
  """

  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, warn: false

  alias Joblite.Accounts.User
  alias Joblite.Repo

  @primary_key {:id, :binary_id, autogenerate: true}
  @type t :: %__MODULE__{}

  @code_validity_minutes 15
  @max_attempts 5
  @max_codes_per_hour 5
  @rand_bytes 4

  schema "login_codes" do
    field(:code_hash, :binary, redact: true)
    field(:expires_at, :utc_datetime)
    field(:attempts, :integer, default: 0)
    field(:consumed_at, :utc_datetime)
    belongs_to(:user, User, type: :binary_id)

    timestamps(updated_at: false, type: :utc_datetime)
  end

  @doc "Issues a code for the user and returns its plaintext exactly once."
  @spec issue(User.t()) ::
          {:ok, String.t()} | {:error, {:rate_limited, pos_integer()}}
  def issue(%User{id: user_id}) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    case recent_codes(user_id, now) do
      codes when length(codes) >= @max_codes_per_hour ->
        oldest = Enum.min_by(codes, & &1.inserted_at)
        available_at = DateTime.add(oldest.inserted_at, 3600, :second)

        {:error, {:rate_limited, max(DateTime.diff(available_at, now, :second), 1)}}

      _codes ->
        code = generate_code()

        Repo.update_all(
          from(login_code in __MODULE__,
            where: login_code.user_id == ^user_id and is_nil(login_code.consumed_at)
          ),
          set: [consumed_at: now]
        )

        %__MODULE__{}
        |> changeset(%{
          user_id: user_id,
          code_hash: hash_code(code),
          expires_at: DateTime.add(now, @code_validity_minutes, :minute)
        })
        |> Repo.insert!()

        {:ok, code}
    end
  end

  @doc "Consumes the current code and confirms the account when the code matches."
  @spec verify(User.t(), term()) :: {:ok, User.t()} | {:error, :invalid_code}
  def verify(%User{} = user, raw_code) do
    case current_code(user.id) do
      nil ->
        {:error, :invalid_code}

      code ->
        cond do
          code.attempts >= @max_attempts ->
            {:error, :invalid_code}

          expired?(code) ->
            {:error, :invalid_code}

          matches?(code, raw_code) ->
            consume(code, user)

          true ->
            record_failed_attempt(code)
            {:error, :invalid_code}
        end
    end
  end

  @doc "Cancels every unused code for the account."
  @spec revoke(User.t()) :: :ok
  def revoke(%User{id: user_id}) do
    Repo.delete_all(
      from(login_code in __MODULE__,
        where: login_code.user_id == ^user_id and is_nil(login_code.consumed_at)
      )
    )

    :ok
  end

  @doc "The SHA-256 hash stored for a code. Exposed for verification tests."
  @spec hash_code(String.t()) :: binary()
  def hash_code(code) when is_binary(code) do
    :crypto.hash(:sha256, code)
  end

  defp recent_codes(user_id, now) do
    since = DateTime.add(now, -3600, :second)

    Repo.all(
      from(login_code in __MODULE__,
        where: login_code.user_id == ^user_id and login_code.inserted_at > ^since,
        order_by: [asc: login_code.inserted_at]
      )
    )
  end

  defp generate_code do
    value = :crypto.strong_rand_bytes(@rand_bytes) |> :binary.decode_unsigned()
    value |> rem(1_000_000) |> Integer.to_string() |> String.pad_leading(6, "0")
  end

  defp current_code(user_id) do
    Repo.one(
      from(login_code in __MODULE__,
        where: login_code.user_id == ^user_id and is_nil(login_code.consumed_at),
        order_by: [desc: login_code.inserted_at],
        limit: 1
      )
    )
  end

  defp expired?(%{expires_at: expires_at}) do
    DateTime.compare(expires_at, DateTime.utc_now() |> DateTime.truncate(:second)) != :gt
  end

  defp matches?(%{code_hash: hash}, raw_code) do
    candidate = raw_code |> normalize_code() |> hash_code()
    secure_compare(hash, candidate)
  end

  defp record_failed_attempt(%{id: id}) do
    Repo.update_all(
      from(login_code in __MODULE__,
        where: login_code.id == ^id and login_code.attempts < @max_attempts
      ),
      inc: [attempts: 1]
    )
  end

  defp normalize_code(raw_code) when is_binary(raw_code) do
    raw_code
    |> String.replace(~r/[^0-9]/, "")
    |> String.slice(0, 6)
  end

  defp normalize_code(_raw_code), do: ""

  defp secure_compare(left, right)
       when is_binary(left) and is_binary(right) and byte_size(left) == byte_size(right) do
    left
    |> :binary.bin_to_list()
    |> Enum.zip(:binary.bin_to_list(right))
    |> Enum.reduce(0, fn {a, b}, acc -> Bitwise.bor(acc, Bitwise.bxor(a, b)) end)
    |> Kernel.==(0)
  end

  defp secure_compare(_left, _right), do: false

  defp consume(code, user) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    Repo.transaction(fn ->
      case Repo.update_all(
             from(login_code in __MODULE__,
               where: login_code.id == ^code.id and is_nil(login_code.consumed_at)
             ),
             set: [consumed_at: now]
           ) do
        {1, _} -> :ok
        {0, _} -> Repo.rollback(:already_consumed)
      end

      Repo.update_all(
        from(login_code in __MODULE__,
          where:
            login_code.user_id == ^user.id and is_nil(login_code.consumed_at) and
              login_code.id != ^code.id
        ),
        set: [consumed_at: now]
      )

      if is_nil(user.confirmed_at) do
        user
        |> User.confirm_changeset()
        |> Repo.update!()
      else
        user
      end
    end)
    |> case do
      {:ok, confirmed} -> {:ok, confirmed}
      {:error, _reason} -> {:error, :invalid_code}
    end
  end

  defp changeset(login_code, attrs) do
    login_code
    |> cast(attrs, [:user_id, :code_hash, :expires_at])
    |> validate_required([:user_id, :code_hash, :expires_at])
  end
end
