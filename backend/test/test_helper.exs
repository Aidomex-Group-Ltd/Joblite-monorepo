ExUnit.start()

# Sandbox mode :manual: connections are only granted through DataCase's
# start_owner!/2 (or explicit allow/3), so leaked connections fail loudly
# instead of silently checking out one per process.
Ecto.Adapters.SQL.Sandbox.mode(Joblite.Repo, :manual)
