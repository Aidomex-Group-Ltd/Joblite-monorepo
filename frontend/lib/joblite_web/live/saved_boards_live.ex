defmodule JobliteWeb.SavedBoardsLive do
  @moduledoc """
  The boards an account saved and the boards it hid.

  The list belongs to the account: it is read from the core context with the
  identity of the current session, and every change is authorized again when
  the event arrives. The hidden boards are the ones the account dismissed from
  the feed; they wait here until the account brings one back.
  """
  use Phoenix.LiveView, layout: {JobliteWeb.Layouts, :app}

  alias Joblite.JobBoards
  alias JobliteWeb.UserAuth

  import JobliteWeb.ExploreLive.Components.BoardCard

  embed_templates("saved_boards_live/render.html")

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:page_title, "Saved boards")
      |> assign(:notice, nil)

    {:ok, load_saved(socket)}
  end

  @impl true
  def handle_event("boards:unsave", %{"id" => id}, socket) do
    case signed_in(socket) do
      {:ok, user} ->
        :ok = JobBoards.unsave_board(user, id)

        {:noreply,
         socket
         |> assign(:notice, "Board removed from your saved boards.")
         |> load_saved()}

      {:error, :not_signed_in} ->
        {:noreply, assign(socket, :notice, "Log in to change your saved boards.")}
    end
  end

  def handle_event("boards:revisit", %{"id" => id}, socket) do
    case signed_in(socket) do
      {:ok, user} ->
        :ok = JobBoards.revisit_board(user, id)

        {:noreply,
         socket
         |> assign(:notice, "Board brought back. It may show up in the feed again.")
         |> load_saved()}

      {:error, :not_signed_in} ->
        {:noreply, assign(socket, :notice, "Log in to change your hidden boards.")}
    end
  end

  def handle_event(_event, _params, socket) do
    {:noreply, assign(socket, :notice, "That action is unavailable.")}
  end

  defp load_saved(socket) do
    user = socket.assigns.current_user

    socket
    |> assign_async(:saved, fn ->
      case JobBoards.saved_boards(user) do
        {:ok, boards} -> {:ok, %{saved: boards}}
        {:error, reason} -> {:error, reason}
      end
    end)
    |> assign_async(:hidden, fn ->
      case JobBoards.dismissed_boards(user) do
        {:ok, boards} -> {:ok, %{hidden: boards}}
        {:error, reason} -> {:error, reason}
      end
    end)
  end

  defp signed_in(socket) do
    case UserAuth.current_user(socket) do
      nil -> {:error, :not_signed_in}
      user -> {:ok, user}
    end
  end
end
