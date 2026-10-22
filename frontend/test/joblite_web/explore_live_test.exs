defmodule JobliteWeb.ExploreLiveTest do
  use JobliteWeb.ConnCase, async: false

  alias Joblite.Accounts

  setup do
    {:ok, user} =
      Accounts.register_user(%{email: "explore@example.com", password: "secret-pass-1"})

    %{user: user}
  end

  defp signed_in(conn, user) do
    init_test_session(conn, %{user_token: Accounts.generate_user_session_token(user)})
  end

  describe "GET /explore" do
    test "lists the registered boards with the status of their integration", %{conn: conn} do
      {:ok, view, html} = live(conn, "/explore")
      assert html =~ "Explore job boards"
      render_async(view, 1_000)

      assert has_element?(view, "#board-remote-ok")
      assert has_element?(view, "#board-jobicy")
      assert has_element?(view, "#board-himalayas")
      assert has_element?(view, "#board-remotive")
    end

    test "shows simple descriptions and links out to every board", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/explore")
      render_async(view, 1_000)

      assert has_element?(
               view,
               "#board-remote-ok .jf-board-note",
               "Find remote job listings across a range of roles and industries."
             )

      assert has_element?(
               view,
               "#board-remotive .jf-board-note",
               "Explore job listings on this job board."
             )

      assert has_element?(view, "#board-remote-ok .jf-board-mode", "Worldwide remote")
      assert has_element?(view, "#board-jobicy .jf-board-mode", "Remote opportunities")
      assert has_element?(view, "#board-jobget .jf-board-mode", "Remote opportunities")

      assert has_element?(view, "#board-remote-ok a.jf-board-open", "Visit job board")
      assert has_element?(view, "#board-remote-ok a.jf-board-open[href='https://remoteok.com/']")
      assert has_element?(view, "#board-remote-ok a.jf-board-open[target='_blank']")
    end

    test "keeps import, coverage and verification details internal", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/explore")
      render_async(view, 1_000)

      html = render(view)

      refute has_element?(view, "#board-remote-ok .jf-board-terms")
      refute has_element?(view, "#board-remote-ok .jf-board-status")
      refute has_element?(view, "#board-remote-ok .jf-board-coverage")
      refute has_element?(view, "#board-remote-ok .jf-board-facts")

      refute html =~ "Coverage confirmed"
      refute html =~ "published terms"
      refute html =~ "2026-10-21"
      refute html =~ "Synchronization"
      refute html =~ "Last import error"
    end

    test "filters the directory by text and by region", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/explore")
      render_async(view, 1_000)

      view |> form("#explore-filters", %{"text" => "remote ok"}) |> render_change()
      render_async(view, 1_000)

      assert has_element?(view, "#board-remote-ok")
      refute has_element?(view, "#board-remotive")

      view |> form("#explore-filters", %{"text" => "", "region" => "europe"}) |> render_change()
      render_async(view, 1_000)

      assert has_element?(view, "#board-himalayas")
      refute has_element?(view, "#board-jobget")
    end

    test "an unknown filter value never reaches the directory", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/explore")
      render_async(view, 1_000)

      render_click(view, "boards:filter", %{"text" => "", "region" => "atlantis"})
      render_async(view, 1_000)

      assert has_element?(view, "#board-remote-ok")
      assert has_element?(view, "#board-jobget")
    end

    test "an empty result explains the filters instead of showing nothing", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/explore")
      render_async(view, 1_000)

      view
      |> form("#explore-filters", %{"text" => "no board carries this name"})
      |> render_change()

      render_async(view, 1_000)

      assert has_element?(view, ".jf-explore-state h2", "No board matches these filters.")
    end
  end

  describe "the remote availability of a board" do
    test "only claims worldwide remote when the board supports it", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/explore")
      render_async(view, 1_000)

      assert has_element?(view, "#board-remote-ok .jf-board-mode", "Worldwide remote")
      assert has_element?(view, "#board-jobicy .jf-board-mode", "Remote opportunities")
      assert has_element?(view, "#board-jobget .jf-board-mode", "Remote opportunities")

      refute has_element?(view, "#board-remote-ok .jf-board-coverage")
      refute has_element?(view, "#board-remote-ok .jf-board-facts")
    end
  end

  describe "the discovery preferences" do
    test "an anonymous visitor is offered the login instead of the form", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/explore")

      assert has_element?(view, "#explore-preferences a[href='/users/log-in']")
      refute has_element?(view, "#explore-preferences-form")
    end

    test "a signed in visitor saves the region and the flag", %{conn: conn, user: user} do
      conn = signed_in(conn, user)
      {:ok, view, _html} = live(conn, "/explore")

      view
      |> form("#explore-preferences-form", %{"region" => "europe", "worldwide_only" => "true"})
      |> render_submit()

      assert has_element?(view, "#explore-notice", "Preferences saved.")

      assert {:ok, preferences} = Joblite.JobBoards.preferences(user)
      assert preferences.region == :europe
      assert preferences.worldwide_only
    end

    test "the categories of the form reach the account", %{conn: conn, user: user} do
      conn = signed_in(conn, user)
      {:ok, view, _html} = live(conn, "/explore")

      render_submit(view, "preferences:save", %{
        "region" => "",
        "categories" => ["engineering", "design"],
        "worldwide_only" => "false"
      })

      assert {:ok, preferences} = Joblite.JobBoards.preferences(user)
      assert preferences.categories == ["engineering", "design"]
      assert preferences.region == nil
      refute preferences.worldwide_only
    end

    test "an unknown category is refused instead of stored", %{conn: conn, user: user} do
      conn = signed_in(conn, user)
      {:ok, view, _html} = live(conn, "/explore")

      render_submit(view, "preferences:save", %{"categories" => ["astrology"]})

      assert has_element?(view, "#explore-notice", "could not be saved")
      assert {:ok, preferences} = Joblite.JobBoards.preferences(user)
      assert preferences.categories == []
    end

    test "the saved preferences are shown when the page opens again", %{conn: conn, user: user} do
      {:ok, _preference} =
        Joblite.JobBoards.save_preferences(user, %{
          region: :europe,
          categories: ["engineering"]
        })

      conn = signed_in(conn, user)
      {:ok, view, _html} = live(conn, "/explore")

      assert has_element?(view, "[data-preference-summary]", "Europe")
      assert has_element?(view, "[data-preference-summary]", "Engineering")
    end

    test "the preferences are cleared again", %{conn: conn, user: user} do
      {:ok, _preference} =
        Joblite.JobBoards.save_preferences(user, %{region: :europe, worldwide_only: true})

      conn = signed_in(conn, user)
      {:ok, view, _html} = live(conn, "/explore")

      render_click(view, "preferences:reset")

      assert has_element?(view, "#explore-notice", "Preferences cleared.")

      assert {:ok, preferences} = Joblite.JobBoards.preferences(user)
      assert preferences.region == nil
      refute preferences.worldwide_only
    end

    test "an anonymous visitor cannot save preferences", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/explore")

      render_submit(view, "preferences:save", %{"region" => "europe"})

      assert has_element?(view, "#explore-notice", "Log in to save your preferences.")
    end
  end

  describe "saving a board" do
    test "an anonymous visitor is asked to log in", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/explore")
      render_async(view, 1_000)

      view |> element("#board-remote-ok button", "Save board") |> render_click()

      assert has_element?(view, "#explore-notice", "Log in to save a board.")
    end

    test "a signed in visitor saves a board and can remove it again", %{conn: conn, user: user} do
      conn = signed_in(conn, user)
      {:ok, view, _html} = live(conn, "/explore")
      render_async(view, 1_000)

      view |> element("#board-remote-ok button", "Save board") |> render_click()
      assert has_element?(view, "#explore-notice", "Board saved.")
      assert has_element?(view, "#board-remote-ok button", "Saved")

      view |> element("#board-remote-ok button", "Saved") |> render_click()
      assert has_element?(view, "#explore-notice", "Board removed")
      assert has_element?(view, "#board-remote-ok button", "Save board")
    end

    test "an unknown board id is refused", %{conn: conn, user: user} do
      conn = signed_in(conn, user)
      {:ok, view, _html} = live(conn, "/explore")
      render_async(view, 1_000)

      render_click(view, "boards:save", %{"id" => "00000000-0000-0000-0000-000000000000"})

      assert has_element?(view, "#explore-notice", "no longer in the directory")
    end
  end
end
