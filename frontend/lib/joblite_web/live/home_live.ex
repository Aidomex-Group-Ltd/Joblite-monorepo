defmodule JobliteWeb.HomeLive do
  @moduledoc """
  A modular candidate feed with explicit session-only preview state.

  The feed carries one job board discovery card. The card comes from the
  registry in the core, is placed among the candidate posts and is labelled
  directory content. A database-backed 30-minute cycle rotates the board on
  the server; the page schedules a refresh when the next cycle begins.
  """
  use Phoenix.LiveView, layout: {JobliteWeb.Layouts, :app}

  alias Joblite.JobBoards
  alias JobliteWeb.HomeLive.{FeedState, PostForm, Uploads}
  alias JobliteWeb.UserAuth
  import JobliteWeb.HomeLive.Components.FeedShell
  import JobliteWeb.HomeLive.Components.FeedStream
  import JobliteWeb.HomeLive.Components.Composer
  import JobliteWeb.HomeLive.Components.MediaViewer

  embed_templates("home_live/render.html")

  @impl true
  def mount(_params, _session, socket) do
    cycle = JobBoards.discovery_cycle()

    socket =
      socket
      |> assign(:feed, FeedState.new())
      |> assign(:architecture, Joblite.Health.architecture())
      |> assign(:excluded_boards, [])
      |> assign(:discovery_offset, cycle.offset)
      |> schedule_discovery_refresh(cycle.next_at)
      |> assign(:upload_error, nil)
      |> Phoenix.LiveView.allow_upload(:media, Uploads.config())

    {:ok, load_discovery(socket)}
  end

  @impl true
  def handle_info(:refresh_discovery, socket) do
    cycle = JobBoards.discovery_cycle()

    socket =
      socket
      |> assign(:discovery_offset, cycle.offset)
      |> schedule_discovery_refresh(cycle.next_at)
      |> load_discovery()

    {:noreply, socket}
  end

  @impl true
  def handle_event("feed:page", %{"page" => page}, socket) do
    change_feed(socket, FeedState.select_page(socket.assigns.feed, page))
  end

  def handle_event("feed:tab", %{"tab" => tab}, socket) do
    change_feed(socket, FeedState.select_tab(socket.assigns.feed, tab))
  end

  def handle_event("feed:like", %{"id" => id}, socket) do
    change_feed(socket, FeedState.toggle(socket.assigns.feed, :liked, id))
  end

  def handle_event("feed:save", %{"id" => id}, socket) do
    change_feed(socket, FeedState.toggle(socket.assigns.feed, :saved, id))
  end

  def handle_event("feed:preview-post", params, socket) do
    with {:ok, attrs} <- PostForm.parse(params),
         {:ok, feed} <- FeedState.prepend(socket.assigns.feed, attrs) do
      {:reply, %{ok: true}, assign(socket, :feed, feed)}
    else
      {:error, reason} -> {:reply, %{ok: false, error: reason}, socket}
    end
  end

  def handle_event("validate-media", _params, socket) do
    socket =
      Enum.reduce(socket.assigns.uploads.media.entries, socket, fn entry, socket ->
        case Uploads.validate(entry) do
          :ok ->
            socket

          {:error, reason} ->
            socket
            |> Phoenix.LiveView.cancel_upload(:media, entry.ref)
            |> assign(:upload_error, reason)
        end
      end)

    {:noreply, socket}
  end

  def handle_event("submit-post", params, socket) do
    uploaded = Uploads.consume(socket, :media)

    case PostForm.parse(params, uploaded) do
      {:ok, attrs} ->
        case FeedState.prepend(socket.assigns.feed, attrs) do
          {:ok, feed} ->
            {:noreply, socket |> assign(:feed, feed) |> assign(:upload_error, nil)}

          {:error, reason} ->
            {:noreply, assign(socket, :upload_error, reason)}
        end

      {:error, reason} ->
        {:noreply, assign(socket, :upload_error, reason)}
    end
  end

  def handle_event("feed:about", _params, socket) do
    feed = %{socket.assigns.feed | show_about: not socket.assigns.feed.show_about}
    {:noreply, assign(socket, :feed, feed)}
  end

  def handle_event("boards:save", %{"id" => id}, socket) do
    with {:ok, user} <- signed_in(socket),
         {:ok, _saved} <- JobBoards.save_board(user, id) do
      {:noreply, notice(socket, "Board saved.")}
    else
      {:error, :not_signed_in} ->
        {:noreply, notice(socket, "Log in to save a board.")}

      {:error, :unknown_source} ->
        {:noreply, notice(socket, "That board is no longer in the directory.")}
    end
  end

  def handle_event("boards:dismiss", %{"id" => id}, socket) do
    case UserAuth.current_user(socket) do
      nil ->
        {:noreply,
         socket
         |> exclude_board(id)
         |> load_discovery()
         |> notice("Board dismissed for this session.")}

      user ->
        case JobBoards.dismiss_board(user, id) do
          {:ok, _dismissal} ->
            {:noreply,
             socket
             |> exclude_board(id)
             |> load_discovery()
             |> notice("Board dismissed.")}

          {:error, :unknown_source} ->
            {:noreply, notice(socket, "That board is no longer in the directory.")}
        end
    end
  end

  def handle_event(_event, _params, socket) do
    {:noreply,
     assign(socket, :feed, %{socket.assigns.feed | notice: "That action is unavailable."})}
  end

  @doc "The discovery card of the feed, or nil while the registry is loading."
  @spec discovery_card(Phoenix.LiveView.AsyncResult.t()) :: map() | nil
  def discovery_card(%Phoenix.LiveView.AsyncResult{ok?: true, result: [card | _rest]}), do: card
  def discovery_card(_result), do: nil

  defp schedule_discovery_refresh(socket, next_at) do
    if connected?(socket) do
      milliseconds = max(DateTime.diff(next_at, DateTime.utc_now(), :millisecond), 1_000)
      Process.send_after(self(), :refresh_discovery, milliseconds)
    end

    socket
  end

  defp load_discovery(socket) do
    user = socket.assigns.current_user
    offset = socket.assigns.discovery_offset
    excluded = socket.assigns.excluded_boards

    assign_async(socket, :discovery, fn ->
      cards =
        JobBoards.discovery_cards(user,
          limit: 1,
          exclude_source_ids: excluded,
          offset: offset
        )

      {:ok, %{discovery: cards}}
    end)
  end

  defp exclude_board(socket, id) do
    assign(socket, :excluded_boards, socket.assigns.excluded_boards ++ [id])
  end

  defp signed_in(socket) do
    case UserAuth.current_user(socket) do
      nil -> {:error, :not_signed_in}
      user -> {:ok, user}
    end
  end

  defp notice(socket, message) do
    assign(socket, :feed, %{socket.assigns.feed | notice: message})
  end

  defp change_feed(socket, {:ok, feed}), do: {:noreply, assign(socket, :feed, feed)}

  defp change_feed(socket, {:error, message}) do
    {:noreply, assign(socket, :feed, %{socket.assigns.feed | notice: message})}
  end
end
