defmodule Joblite.JobBoards.Sync.Transport do
  @moduledoc """
  Default HTTP transport for a synchronization pass.

  The transport returns decoded JSON so adapters only contain normalization
  rules. It is replaceable: a pass receives its own transport function and
  falls back to this one.
  """

  @doc "Fetches a URL and decodes its JSON body."
  @spec get(String.t()) :: {:ok, term()} | {:error, term()}
  def get(url) when is_binary(url) do
    request = {String.to_charlist(url), [{~c"accept", ~c"application/json"}]}

    options = [
      ssl: [verify: :verify_peer, cacerts: :public_key.cacerts_get(), depth: 3],
      timeout: 15_000,
      connect_timeout: 10_000
    ]

    case :httpc.request(:get, request, options, body_format: :binary) do
      {:ok, {{_version, 200, _reason}, _headers, body}} -> decode(body)
      {:ok, {{_version, status, _reason}, _headers, _body}} -> {:error, {:http_status, status}}
      {:error, reason} -> {:error, reason}
    end
  end

  defp decode(body) do
    {:ok, JSON.decode!(body)}
  rescue
    _error -> {:error, :invalid_json}
  end
end
