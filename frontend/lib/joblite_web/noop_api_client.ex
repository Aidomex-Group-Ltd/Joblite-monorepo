defmodule JobliteWeb.NoopApiClient do
  @moduledoc """
  Joblite sends mail over SMTP, not through an HTTP API. Swoosh still expects an
  API client at startup; this one fails explicitly if an HTTP adapter is ever
  configured by mistake.
  """

  @behaviour Swoosh.ApiClient

  @impl true
  def init, do: :ok

  @impl true
  def post(_url, _headers, _body, _email), do: {:error, :http_mail_adapter_not_configured}
end
