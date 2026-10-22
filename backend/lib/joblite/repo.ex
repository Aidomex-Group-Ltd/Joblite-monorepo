defmodule Joblite.Repo do
  @moduledoc "The only Ecto repository in the Joblite monolith."
  use Ecto.Repo, otp_app: :joblite_core, adapter: Ecto.Adapters.Postgres
end
