defmodule JobliteWeb.ExploreLive do
  @moduledoc """
  The global job board directory.

  Every board Joblite knows is listed with the permission decision that decides
  how it may be used: a feed candidate whose listings may be imported, a
  directory only board that stays an outbound link, or a board whose written
  permission is still pending. A board is always an outbound link here, and an
  imported listing is never presented as a Joblite posting.

  The screen also holds the discovery preferences of the account. They rank the
  boards the feed promotes, so the reader chooses them once instead of on every
  visit.
  """
  use Phoenix.LiveView, layout: {JobliteWeb.Layouts, :app}

  alias Joblite.JobBoards
  alias JobliteWeb.ExploreLive.DirectoryFilters
  alias JobliteWeb.UserAuth

  import JobliteWeb.ExploreLive.Components.BoardCard
  import JobliteWeb.ExploreLive.Components.PreferencesPanel

  embed_templates("explore_live/render.html")

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    {preferences, preferences_available} = preferences(user)

    socket =
      socket
      |> assign(:page_title, "Explore job boards")
      |> assign(:filters, DirectoryFilters.new())
      |> assign(:options, JobBoards.directory_options())
      |> assign(:saved_ids, saved_ids(user))
      |> assign(:preferences, preferences)
      |> assign(:preferences_available, preferences_available)
      |> assign(:notice, nil)

    {:ok, load_directory(socket)}
  end

  @impl true
  def handle_event("boards:filter", params, socket) do
    filters = DirectoryFilters.apply(socket.assigns.filters, params)

    {:noreply,
     socket
     |> assign(:filters, filters)
     |> load_directory()}
  end

  def handle_event("boards:save", %{"id" => id}, socket) do
    with {:ok, user} <- signed_in(socket),
         {:ok, _saved} <- JobBoards.save_board(user, id) do
      {:noreply,
       socket
       |> assign(:saved_ids, MapSet.put(socket.assigns.saved_ids, id))
       |> assign(:notice, "Board saved. Find it under Saved boards.")}
    else
      {:error, :not_signed_in} ->
        {:noreply, assign(socket, :notice, "Log in to save a board.")}

      {:error, :unknown_source} ->
        {:noreply, assign(socket, :notice, "That board is no longer in the directory.")}
    end
  end

  def handle_event("boards:unsave", %{"id" => id}, socket) do
    case signed_in(socket) do
      {:ok, user} ->
        :ok = JobBoards.unsave_board(user, id)

        {:noreply,
         socket
         |> assign(:saved_ids, MapSet.delete(socket.assigns.saved_ids, id))
         |> assign(:notice, "Board removed from your saved boards.")}

      {:error, :not_signed_in} ->
        {:noreply, assign(socket, :notice, "Log in to change your saved boards.")}
    end
  end

  def handle_event("preferences:save", params, socket) do
    with {:ok, user} <- signed_in(socket),
         {:ok, saved} <- JobBoards.save_preferences(user, preference_attrs(params)) do
      {:noreply,
       socket
       |> assign(:preferences, saved)
       |> assign(:notice, "Preferences saved. The feed now prefers these boards.")}
    else
      {:error, :not_signed_in} ->
        {:noreply, assign(socket, :notice, "Log in to save your preferences.")}

      {:error, _changeset} ->
        {:noreply, assign(socket, :notice, "Those preferences could not be saved.")}
    end
  end

  def handle_event("preferences:reset", _params, socket) do
    with {:ok, user} <- signed_in(socket),
         {:ok, saved} <- JobBoards.save_preferences(user, %{}) do
      {:noreply,
       socket
       |> assign(:preferences, saved)
       |> assign(:notice, "Preferences cleared.")}
    else
      {:error, :not_signed_in} ->
        {:noreply, assign(socket, :notice, "Log in to change your preferences.")}

      {:error, _changeset} ->
        {:noreply, assign(socket, :notice, "Those preferences could not be cleared.")}
    end
  end

  def handle_event(_event, _params, socket) do
    {:noreply, assign(socket, :notice, "That action is unavailable.")}
  end

  defp load_directory(socket) do
    filters = socket.assigns.filters

    assign_async(socket, :directory, fn ->
      case JobBoards.directory(DirectoryFilters.to_query(filters)) do
        {:ok, boards} -> {:ok, %{directory: boards}}
        {:error, reason} -> {:error, reason}
      end
    end)
  end

  defp saved_ids(nil), do: MapSet.new()

  defp saved_ids(user) do
    case JobBoards.saved_boards(user) do
      {:ok, boards} -> MapSet.new(boards, & &1.id)
      {:error, _reason} -> MapSet.new()
    end
  end

  defp preferences(nil), do: {nil, true}

  defp preferences(user) do
    case JobBoards.preferences(user) do
      {:ok, preference} -> {preference, true}
      {:error, :registry_unavailable} -> {nil, false}
    end
  end

  # The form sends plain values. They are handed to the core as they arrived;
  # the core matches them against its own vocabulary and refuses what it does
  # not know.
  defp preference_attrs(params) do
    %{
      region: Map.get(params, "region"),
      categories: Map.get(params, "categories") || [],
      worldwide_only: Map.get(params, "worldwide_only") in ["true", "on", "1"]
    }
  end

  defp signed_in(socket) do
    case UserAuth.current_user(socket) do
      nil -> {:error, :not_signed_in}
      user -> {:ok, user}
    end
  end
end
