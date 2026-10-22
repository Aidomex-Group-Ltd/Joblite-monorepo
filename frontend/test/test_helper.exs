ExUnit.start()

# Sandbox mode :manual: connections are only granted through ConnCase's
# start_owner!/2, so a LiveView or plug process that touches the database
# without ownership fails loudly instead of silently pooling its own.
Ecto.Adapters.SQL.Sandbox.mode(Joblite.Repo, :manual)
