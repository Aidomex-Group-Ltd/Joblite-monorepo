defmodule Joblite.AccountsTest do
  use Joblite.DataCase, async: true

  alias Joblite.Accounts
  alias Joblite.Accounts.{LoginCode, User, UserToken}

  defp valid_registration do
    %{email: "Ada@Example.COM", password: "correct-horse-1"}
  end

  describe "register_user/1" do
    test "creates a user with normalized email and bcrypt-hashed password" do
      assert {:ok, %User{} = user} = Accounts.register_user(valid_registration())
      assert user.email == "ada@example.com"
      assert user.hashed_password != "correct-horse-1"
      assert Bcrypt.verify_pass("correct-horse-1", user.hashed_password)
      refute Bcrypt.verify_pass("wrong-password", user.hashed_password)
    end

    test "rejects duplicate identity case-insensitively" do
      assert {:ok, _} = Accounts.register_user(valid_registration())

      assert {:error, changeset} =
               Accounts.register_user(%{email: "ADA@example.com", password: "another-pass-1"})

      assert "has already been taken" in errors_on(changeset).email
    end

    test "rejects invalid email and short password" do
      assert {:error, changeset} =
               Accounts.register_user(%{email: "not-an-email", password: "short"})

      assert "can't be blank" in errors_on(changeset).email or
               "has invalid format" in errors_on(changeset).email

      assert "should be at least 8 character(s)" in errors_on(changeset).password
    end

    test "does not create a user when password is missing" do
      assert {:error, changeset} = Accounts.register_user(%{email: "nobody@example.com"})
      assert "can't be blank" in errors_on(changeset).password
      refute Repo.get_by(User, email: "nobody@example.com")
    end
  end

  describe "get_user_by_email/1" do
    test "finds a user regardless of input case" do
      {:ok, user} = Accounts.register_user(valid_registration())
      assert %User{id: id} = Accounts.get_user_by_email("ADA@EXAMPLE.COM")
      assert id == user.id
    end

    test "returns nil for unknown identity" do
      refute Accounts.get_user_by_email("ghost@example.com")
    end
  end

  describe "authenticate_by_email_password/2" do
    setup do
      {:ok, user} = Accounts.register_user(valid_registration())
      %{user: user}
    end

    test "returns the user for the correct password", %{user: user} do
      assert {:ok, authenticated} =
               Accounts.authenticate_by_email_password("ada@example.com", "correct-horse-1")

      assert authenticated.id == user.id
    end

    test "normalizes email case before lookup", %{user: user} do
      assert {:ok, authenticated} =
               Accounts.authenticate_by_email_password("ADA@EXAMPLE.COM", "correct-horse-1")

      assert authenticated.id == user.id
    end

    test "rejects a wrong password" do
      assert {:error, :invalid_credentials} =
               Accounts.authenticate_by_email_password("ada@example.com", "not-the-password")
    end

    test "rejects an unknown email through the dummy-verify path" do
      assert {:error, :invalid_credentials} =
               Accounts.authenticate_by_email_password("ghost@example.com", "whatever-pass")
    end
  end

  describe "passwordless signup and login codes" do
    test "creates a confirmed-by-code account without a password" do
      assert {:ok, %User{} = user, :new} =
               Accounts.start_passwordless_signup(%{
                 email: "Mira@Example.com",
                 name: "Mira Chen",
                 role: "candidate"
               })

      assert user.email == "mira@example.com"
      assert user.name == "Mira Chen"
      assert user.role == "candidate"
      assert is_nil(user.hashed_password)
      assert is_nil(user.confirmed_at)
    end

    test "an existing email is returned as :existing without changing the account" do
      {:ok, original} =
        Accounts.register_user(%{email: "ada@example.com", password: "correct-horse-1"})

      assert {:ok, %User{} = user, :existing} =
               Accounts.start_passwordless_signup(%{
                 email: "ADA@example.com",
                 name: "Someone Else",
                 role: "employer"
               })

      assert user.id == original.id
      assert user.name == nil
      assert user.role == "candidate"
      assert user.hashed_password == original.hashed_password
    end

    test "requires a name and a known role for a new account" do
      assert {:error, changeset} =
               Accounts.start_passwordless_signup(%{
                 email: "new@example.com",
                 name: "",
                 role: "admin"
               })

      assert "can't be blank" in errors_on(changeset).name
      assert "is invalid" in errors_on(changeset).role
      refute Accounts.get_user_by_email("new@example.com")
    end

    test "login code is stored only as a hash, expires, and confirms on use" do
      {:ok, user, :new} =
        Accounts.start_passwordless_signup(%{
          email: "code@example.com",
          name: "Code User",
          role: "employer"
        })

      assert {:ok, {:issued, issued_user, code}} = Accounts.issue_login_code(user.email)
      assert issued_user.id == user.id
      assert code =~ ~r/^\d{6}$/

      stored = Repo.get_by!(LoginCode, user_id: user.id)
      assert stored.code_hash == LoginCode.hash_code(code)
      assert stored.code_hash != code
      assert DateTime.compare(stored.expires_at, DateTime.utc_now()) == :gt

      assert {:ok, confirmed} = Accounts.verify_login_code(user, code)
      assert confirmed.id == user.id
      assert %DateTime{} = confirmed.confirmed_at
      assert {:error, :invalid_code} = Accounts.verify_login_code(confirmed, code)
    end

    test "rejects a wrong code and stops after five attempts" do
      {:ok, user, :new} =
        Accounts.start_passwordless_signup(%{
          email: "attempt@example.com",
          name: "Attempt User",
          role: "candidate"
        })

      {:ok, {:issued, user, _code}} = Accounts.issue_login_code(user.email)

      for _ <- 1..5 do
        assert {:error, :invalid_code} = Accounts.verify_login_code(user, "000000")
      end

      assert {:error, :invalid_code} = Accounts.verify_login_code(user, "000000")
    end

    test "unknown emails are ignored without creating an account" do
      assert {:ok, :ignored} = Accounts.issue_login_code("ghost@example.com")
      refute Accounts.get_user_by_email("ghost@example.com")
    end

    test "limits code requests to five per hour per account" do
      {:ok, user, :new} =
        Accounts.start_passwordless_signup(%{
          email: "rate@example.com",
          name: "Rate User",
          role: "candidate"
        })

      for _ <- 1..5 do
        assert {:ok, {:issued, _, _}} = Accounts.issue_login_code(user.email)
      end

      assert {:error, {:rate_limited, seconds}} = Accounts.issue_login_code(user.email)
      assert seconds > 0 and seconds <= 3600
    end
  end

  describe "session token lifecycle" do
    setup do
      {:ok, user} = Accounts.register_user(valid_registration())
      %{user: user}
    end

    test "round trip: generate returns the raw token once; lookup returns the user", %{user: user} do
      raw = Accounts.generate_user_session_token(user)
      assert is_binary(raw)
      assert %User{id: id} = Accounts.get_user_by_session_token(raw)
      assert id == user.id
    end

    test "only the hash is stored, never the raw token", %{user: user} do
      raw = Accounts.generate_user_session_token(user)
      stored = Repo.one!(UserToken)
      assert stored.token == UserToken.hash_token(raw)
      assert stored.token != raw
      assert stored.context == "session"
      assert stored.user_id == user.id
    end

    test "revocation: deleted token no longer resolves; delete is idempotent", %{user: user} do
      raw = Accounts.generate_user_session_token(user)
      assert :ok = Accounts.delete_user_session_token(raw)
      refute Accounts.get_user_by_session_token(raw)
      assert :ok = Accounts.delete_user_session_token(raw)
    end

    test "expiry: token older than the validity window no longer resolves", %{user: user} do
      raw = Accounts.generate_user_session_token(user)
      assert Accounts.get_user_by_session_token(raw)

      cutoff = DateTime.add(DateTime.utc_now(), -61, :day)
      Repo.update_all(UserToken, set: [inserted_at: cutoff])

      refute Accounts.get_user_by_session_token(raw)
    end

    test "unknown and malformed tokens resolve to nil" do
      refute Accounts.get_user_by_session_token(:crypto.strong_rand_bytes(32))
      refute Accounts.get_user_by_session_token("")
    end
  end
end
