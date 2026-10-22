defmodule JobliteWeb.SavedBoardsLiveTest do
  use JobliteWeb.ConnCase, async: false

  alias Joblite.Accounts

  setup do
    {:ok, user} = Accounts.register_user(%{email: "saved@example.com", password: "secret-pass-1"})

    %{user: user}
  end

  defp signed_in(conn, user) do
    init_test_session(conn, %{user_token: Accounts.generate_user_session_token(user)})
  end

  describe "GET /explore/saved" do
    test "an anonymous visitor is redirected to the login page", %{conn: conn} do
      assert {:error, {:redirect, %{to: "/users/log-in"}}} = live(conn, "/explore/saved")
    end

    test "an account with no saved board sees the empty state", %{conn: conn, user: user} do
      conn = signed_in(conn, user)
      {:ok, view, _html} = live(conn, "/explore/saved")
      render_async(view, 1_000)

      assert has_element?(view, ".jf-explore-state h2", "No board saved yet.")
    end

    test "a saved board is listed and can be removed", %{conn: conn, user: user} do
      {:ok, source} = Joblite.JobBoards.get_source_by_slug("remote-ok")
      {:ok, _saved} = Joblite.JobBoards.save_board(user, source.id)

      conn = signed_in(conn, user)
      {:ok, view, _html} = live(conn, "/explore/saved")
      render_async(view, 1_000)

      assert has_element?(view, "#saved-board-remote-ok")

      assert has_element?(
               view,
               "#saved-board-remote-ok .jf-board-note",
               "Find remote job listings across a range of roles and industries."
             )

      view |> element("#saved-board-remote-ok button", "Saved") |> render_click()
      render_async(view, 1_000)

      assert has_element?(view, "#saved-notice", "Board removed from your saved boards.")
      assert has_element?(view, ".jf-explore-state h2", "No board saved yet.")
    end

    test "the list belongs to the account and never shows another account's board", %{
      conn: conn,
      user: user
    } do
      {:ok, other} =
        Accounts.register_user(%{email: "other@example.com", password: "secret-pass-1"})

      {:ok, source} = Joblite.JobBoards.get_source_by_slug("jobicy")
      {:ok, _saved} = Joblite.JobBoards.save_board(other, source.id)

      conn = signed_in(conn, user)
      {:ok, view, _html} = live(conn, "/explore/saved")
      render_async(view, 1_000)

      refute has_element?(view, "#saved-board-jobicy")
      assert has_element?(view, ".jf-explore-state h2", "No board saved yet.")
    end
  end

  describe "the hidden boards" do
    test "a dismissed board waits in the hidden list", %{conn: conn, user: user} do
      {:ok, source} = Joblite.JobBoards.get_source_by_slug("jobicy")
      {:ok, _dismissal} = Joblite.JobBoards.dismiss_board(user, source.id)

      conn = signed_in(conn, user)
      {:ok, view, _html} = live(conn, "/explore/saved")
      render_async(view, 1_000)

      assert has_element?(view, "#hidden-board-jobicy")

      assert has_element?(
               view,
               "#hidden-board-jobicy .jf-board-note",
               "Find remote job listings across a range of roles and industries."
             )
    end

    test "a hidden board can be brought back", %{conn: conn, user: user} do
      {:ok, source} = Joblite.JobBoards.get_source_by_slug("jobicy")
      {:ok, _dismissal} = Joblite.JobBoards.dismiss_board(user, source.id)

      conn = signed_in(conn, user)
      {:ok, view, _html} = live(conn, "/explore/saved")
      render_async(view, 1_000)

      view |> element("#hidden-board-jobicy button", "Bring back") |> render_click()
      render_async(view, 1_000)

      assert has_element?(view, "#saved-notice", "Board brought back")
      refute has_element?(view, "#hidden-board-jobicy")
    end

    test "the hidden boards of another account stay hidden", %{conn: conn, user: user} do
      {:ok, other} =
        Accounts.register_user(%{email: "other-hidden@example.com", password: "secret-pass-1"})

      {:ok, source} = Joblite.JobBoards.get_source_by_slug("jobicy")
      {:ok, _dismissal} = Joblite.JobBoards.dismiss_board(other, source.id)

      conn = signed_in(conn, user)
      {:ok, view, _html} = live(conn, "/explore/saved")
      render_async(view, 1_000)

      refute has_element?(view, "#hidden-board-jobicy")
    end
  end
end
