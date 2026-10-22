defmodule Joblite.JobBoards do
  @moduledoc """
  Public boundary for the global job board directory.

  Three responsibilities stay separate here. The registry records every known
  source, its coverage and the permission mode that decides what Joblite may
  do with it. The per-account state records the boards a user saved or
  dismissed. Imported listings exist only for sources whose mode allows
  aggregation, and they never turn a directory link into an imported job.

  Feed discovery cards are assembled from the registry and the account's own
  state; they are labelled directory content and never presented as posts.
  """

  import Ecto.Query, warn: false

  alias Joblite.Accounts.User

  alias Joblite.JobBoards.{
    Card,
    Dismissal,
    Discovery,
    DiscoveryCycle,
    Options,
    Preference,
    SavedBoard,
    Source,
    SourceMode,
    SourceQuery,
    Sync
  }

  alias Joblite.Repo

  @dismissal_days 30

  @doc "Lists the directory boards that match the filters."
  @spec directory(map()) :: {:ok, [map()]} | {:error, :registry_unavailable}
  def directory(filters \\ %{}) do
    {:ok, filters |> SourceQuery.search() |> Repo.all() |> Enum.map(&Card.full/1)}
  rescue
    DBConnection.ConnectionError -> {:error, :registry_unavailable}
  end

  @doc "Fetches one registered source."
  @spec get_source(binary()) :: {:ok, Source.t()} | {:error, :unknown_source}
  def get_source(id) when is_binary(id) do
    case Repo.get(Source, id) do
      nil -> {:error, :unknown_source}
      source -> {:ok, source}
    end
  end

  @doc "Fetches one registered source by its slug."
  @spec get_source_by_slug(binary()) :: {:ok, Source.t()} | {:error, :unknown_source}
  def get_source_by_slug(slug) when is_binary(slug) do
    case Repo.get_by(Source, slug: slug) do
      nil -> {:error, :unknown_source}
      source -> {:ok, source}
    end
  end

  @doc "The vocabulary and notice text the directory screen renders."
  @spec directory_options() :: map()
  def directory_options, do: Options.directory()

  @doc "Saves a board for the account. Saving twice keeps one board."
  @spec save_board(User.t(), binary()) :: {:ok, SavedBoard.t()} | {:error, term()}
  def save_board(%User{} = user, source_id) do
    with {:ok, source} <- get_source(source_id) do
      %SavedBoard{}
      |> SavedBoard.changeset(%{
        user_id: user.id,
        source_id: source.id,
        saved_at: DateTime.utc_now()
      })
      |> Repo.insert(on_conflict: :nothing, conflict_target: [:user_id, :source_id])
    end
  end

  @doc "Removes a board from the account's saved list."
  @spec unsave_board(User.t(), binary()) :: :ok
  def unsave_board(%User{} = user, source_id) do
    Repo.delete_all(
      from(saved in SavedBoard,
        where: saved.user_id == ^user.id and saved.source_id == ^source_id
      )
    )

    :ok
  end

  @doc "Hides a board from feed discovery for the account."
  @spec dismiss_board(User.t(), binary()) :: {:ok, Dismissal.t()} | {:error, term()}
  def dismiss_board(%User{} = user, source_id) do
    with {:ok, source} <- get_source(source_id) do
      now = DateTime.utc_now()

      %Dismissal{}
      |> Dismissal.changeset(%{
        user_id: user.id,
        source_id: source.id,
        dismissed_at: now,
        expires_at: DateTime.add(now, @dismissal_days * 24 * 60 * 60, :second)
      })
      |> Repo.insert(on_conflict: :nothing, conflict_target: [:user_id, :source_id])
    end
  end

  @doc "Clears a dismissal so the board may return to feed discovery."
  @spec revisit_board(User.t(), binary()) :: :ok
  def revisit_board(%User{} = user, source_id) do
    Repo.delete_all(
      from(dismissal in Dismissal,
        where: dismissal.user_id == ^user.id and dismissal.source_id == ^source_id
      )
    )

    :ok
  end

  @doc "The boards the account saved, most recent first."
  @spec saved_boards(User.t()) :: {:ok, [map()]} | {:error, :registry_unavailable}
  def saved_boards(%User{} = user) do
    boards =
      Repo.all(
        from(source in Source,
          join: saved in SavedBoard,
          on: saved.source_id == source.id,
          where: saved.user_id == ^user.id,
          order_by: [desc: saved.saved_at]
        )
      )
      |> Enum.map(&Card.full/1)

    {:ok, boards}
  rescue
    DBConnection.ConnectionError -> {:error, :registry_unavailable}
  end

  @doc "The identifiers of the boards the account dismissed and did not revisit."
  @spec dismissed_source_ids(User.t()) :: MapSet.t()
  def dismissed_source_ids(%User{} = user) do
    user.id
    |> SourceQuery.dismissed_source_ids()
    |> Repo.all()
    |> MapSet.new()
  end

  @doc "The boards the account dismissed, so a board can be brought back."
  @spec dismissed_boards(User.t()) :: {:ok, [map()]} | {:error, :registry_unavailable}
  def dismissed_boards(%User{} = user) do
    boards =
      user.id
      |> SourceQuery.dismissed()
      |> Repo.all()
      |> Enum.map(&Card.full/1)

    {:ok, boards}
  rescue
    DBConnection.ConnectionError -> {:error, :registry_unavailable}
  end

  @doc "The discovery preferences of the account, or neutral defaults."
  @spec preferences(User.t()) :: {:ok, Preference.t()} | {:error, :registry_unavailable}
  def preferences(%User{} = user) do
    case Repo.one(from(preference in Preference, where: preference.user_id == ^user.id)) do
      nil -> {:ok, %Preference{user_id: user.id, categories: [], worldwide_only: false}}
      preference -> {:ok, preference}
    end
  rescue
    DBConnection.ConnectionError -> {:error, :registry_unavailable}
  end

  @doc "Stores the discovery preferences of the account."
  @spec save_preferences(User.t(), map()) :: {:ok, Preference.t()} | {:error, term()}
  def save_preferences(%User{} = user, attrs) do
    attrs = Preference.normalize(attrs)

    case Repo.get_by(Preference, user_id: user.id) do
      nil -> %Preference{user_id: user.id} |> Preference.changeset(attrs) |> Repo.insert()
      preference -> preference |> Preference.changeset(attrs) |> Repo.update()
    end
  end

  @doc """
  The rotation offset of the feed discovery card and when the next 30-minute
  cycle starts. The cycle is stored in the database, not in a browser session.
  """
  @spec discovery_cycle(DateTime.t()) :: %{offset: non_neg_integer(), next_at: DateTime.t()}
  def discovery_cycle(now \\ DateTime.utc_now()), do: DiscoveryCycle.current(now)

  @doc """
  Builds the discovery cards for the feed.

  The pool is the registered sources that may be promoted, minus the boards
  the account dismissed, ranked by the account's preferences. `exclude_ids`
  holds the boards already shown in the current feed. `offset` rotates the
  choice inside the pool; the feed passes the current server cycle offset.
  """
  @spec discovery_cards(User.t() | nil, keyword()) :: [map()]
  def discovery_cards(user, opts \\ []) do
    limit = Keyword.get(opts, :limit, 1)
    shown = Keyword.get(opts, :exclude_source_ids, [])
    offset = Keyword.get(opts, :offset, 0)

    sources =
      SourceQuery.promotable()
      |> Repo.all()
      |> reject_dismissed(user)
      |> Discovery.rank(user && stored_preferences(user))

    sources
    |> Discovery.pick(shown, limit, offset)
    |> Enum.map(&card_for/1)
  end

  @doc "Runs one synchronization pass for a permitted source."
  @spec sync_source(Source.t(), keyword()) :: {:ok, map()} | {:error, term()}
  def sync_source(%Source{} = source, opts \\ []), do: Sync.sync(source, opts)

  defp card_for(source) do
    listing = active_listing(source)
    Card.full(source, listing)
  end

  defp active_listing(%Source{source_mode: mode, id: source_id}) do
    if SourceMode.aggregate?(mode) do
      Repo.one(SourceQuery.active_listings(source_id))
    end
  end

  defp reject_dismissed(sources, nil), do: sources

  defp reject_dismissed(sources, %User{} = user) do
    dismissed = dismissed_source_ids(user)
    Enum.reject(sources, &MapSet.member?(dismissed, &1.id))
  end

  # A registry that cannot be read leaves the ranking neutral instead of
  # failing the whole feed.
  defp stored_preferences(user) do
    case preferences(user) do
      {:ok, preference} -> preference
      {:error, _reason} -> nil
    end
  end
end
