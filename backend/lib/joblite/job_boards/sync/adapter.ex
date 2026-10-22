defmodule Joblite.JobBoards.Sync.Adapter do
  @moduledoc """
  Contract for a job board source adapter.

  An adapter exists only for a source whose published terms allow
  republication. `fetch/2` receives the source and the options of one
  synchronization pass and returns normalized listings. The transport is
  injected so a pass can be exercised without network access.
  """

  alias Joblite.JobBoards.Source

  @type listing :: %{
          required(:external_id) => String.t(),
          required(:canonical_url) => String.t(),
          required(:title) => String.t(),
          optional(:company) => String.t() | nil,
          optional(:location) => String.t() | nil,
          optional(:category) => String.t() | nil,
          optional(:remote_eligibility) => String.t() | nil,
          optional(:published_at) => DateTime.t() | nil,
          optional(:expires_at) => DateTime.t() | nil,
          optional(:attribution) => String.t() | nil
        }

  @callback slug() :: String.t()
  @callback attribution() :: String.t()
  @callback fetch(Source.t(), keyword()) :: {:ok, [listing()]} | {:error, term()}
end
