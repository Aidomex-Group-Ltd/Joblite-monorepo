defmodule JobliteWeb.Emails.LoginCodeEmail do
  @moduledoc "Builds and delivers the one-time sign-in code message."

  import Swoosh.Email

  alias Joblite.Accounts.User
  alias JobliteWeb.Mailer

  @doc "Delivers a sign-in code to the account email."
  @spec deliver(User.t(), String.t()) :: :ok | {:error, term()}
  def deliver(%User{} = user, code) when is_binary(code) do
    user
    |> build(code)
    |> Mailer.deliver()
    |> case do
      {:ok, _receipt} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  @doc "The message sent for a code. Exposed for tests and previews."
  @spec build(User.t(), String.t()) :: Swoosh.Email.t()
  def build(%User{} = user, code) when is_binary(code) do
    new()
    |> from(from_address())
    |> to({user.name || "", user.email})
    |> subject("Your Joblite sign-in code")
    |> text_body(text_body(code))
    |> html_body(html_body(code))
  end

  defp from_address do
    System.get_env("MAIL_FROM", "Joblite <no-reply@joblite.local>")
  end

  defp text_body(code) do
    """
    Your Joblite sign-in code is #{code}.

    It expires in 15 minutes and can be used once. If you did not request it,
    you can ignore this message.
    """
  end

  defp html_body(code) do
    """
    <p>Your Joblite sign-in code is:</p>
    <p style="font-size: 28px; font-weight: 700; letter-spacing: 6px;">#{code}</p>
    <p>It expires in 15 minutes and can be used once. If you did not request it, you can ignore this message.</p>
    """
  end
end
