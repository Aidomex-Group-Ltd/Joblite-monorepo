defmodule JobliteWeb.Mailer do
  @moduledoc "Swoosh mailer. Development and test use the local mailbox."
  use Swoosh.Mailer, otp_app: :joblite_web
end
