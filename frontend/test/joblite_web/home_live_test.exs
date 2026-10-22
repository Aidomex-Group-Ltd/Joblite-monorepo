defmodule JobliteWeb.HomeLiveTest do
  use JobliteWeb.ConnCase, async: false

  alias Joblite.Accounts

  setup do
    {:ok, user} = Accounts.register_user(%{email: "feed@example.com", password: "secret-pass-1"})

    %{user: user}
  end

  defp signed_in(conn, user) do
    init_test_session(conn, %{user_token: Accounts.generate_user_session_token(user)})
  end

  test "initial feed renders thumbnails without video players", %{conn: conn} do
    {:ok, view, html} = live(conn, "/")
    assert html =~ "Good work starts with good people"
    assert has_element?(view, "#post-nova")
    assert has_element?(view, "#post-amina")
    assert has_element?(view, "#post-jordan")
    assert has_element?(view, "#media-nova-0 img[src$='nova-poster.jpg']")
    refute has_element?(view, "#feed-posts video")
  end

  test "following and hiring tabs select the intended preview posts", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/")
    view |> element("#tab-following") |> render_click()
    assert has_element?(view, "#post-amina")
    refute has_element?(view, "#post-nova")
    view |> element("#tab-hiring") |> render_click()
    assert has_element?(view, "#post-nova")
    refute has_element?(view, "#post-amina")
  end

  test "saved posts are reversible and do not cross visits", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/")
    view |> element("#save-nova") |> render_click()
    view |> element("#nav-saved") |> render_click()
    assert has_element?(view, "#post-nova")
    refute has_element?(view, "#post-amina")
    view |> element("#save-nova") |> render_click()
    assert has_element?(view, "#feed-empty")
    {:ok, fresh, _html} = live(conn, "/")
    fresh |> element("#nav-saved") |> render_click()
    assert has_element?(fresh, "#feed-empty")
  end

  test "like events accept only known post ids and navigation values", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/")
    view |> element("#like-nova") |> render_click()
    assert has_element?(view, "#like-nova[aria-pressed='true']")
    render_click(view, "feed:save", %{"id" => "unknown"})
    assert has_element?(view, "#feed-notice", "no longer available")
    render_click(view, "feed:page", %{"page" => "admin"})
    assert has_element?(view, "#feed-notice", "navigation")
    assert has_element?(view, "#post-nova")
  end

  test "preview text is escaped and visible in My posts", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/")

    render_hook(view, "feed:preview-post", %{
      "body" => "A new project <script>alert(1)</script>",
      "media" => []
    })

    assert has_element?(view, "#feed-notice", "No public post")
    view |> element("#nav-mine") |> render_click()
    assert has_element?(view, ".jf-post-text", "A new project <script>alert(1)</script>")
    refute has_element?(view, "#feed-posts script")
    refute has_element?(view, "#post-nova")
  end

  test "valid local media references render placeholders without echoing submitted URLs",
       %{conn: conn} do
    {:ok, view, _html} = live(conn, "/")

    media = %{
      "id" => "local-example-123",
      "kind" => "image",
      "type" => "image/jpeg",
      "name" => "work.jpg",
      "source" => "https://untrusted.invalid/picture"
    }

    html = render_hook(view, "feed:preview-post", %{"body" => "", "media" => [media]})
    assert has_element?(view, "img[data-local-thumbnail='local-example-123']")
    refute html =~ "untrusted.invalid"
  end

  test "empty and malformed preview posts do not add rows", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/")
    render_hook(view, "feed:preview-post", %{"body" => " ", "media" => []})
    render_hook(view, "feed:preview-post", %{"body" => %{}, "media" => []})
    view |> element("#nav-mine") |> render_click()
    assert has_element?(view, "#feed-empty")
  end

  test "core boundary disclosure still works", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/")
    view |> element("#architecture-details") |> render_click()
    assert has_element?(view, "#boundary-explanation", "PostgreSQL")
  end

  test "the desktop frame exposes navigation and a secondary rail", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/")

    assert has_element?(view, ".jf-layout .jf-shell")
    assert has_element?(view, ".jf-rail-left #rail-nav-feed[aria-current='page']")
    assert has_element?(view, ".jf-rail-left #rail-nav-saved")
    assert has_element?(view, ".jf-rail-right .jf-rail-card")
  end

  test "health endpoints: liveness always answers, readiness reflects the database", %{conn: conn} do
    assert %{"status" => "up"} == conn |> get("/health/live") |> json_response(200)
    assert %{"status" => "ready"} == conn |> get("/health/ready") |> json_response(200)
  end

  describe "the job board discovery card" do
    test "one board is offered as labelled directory content among the posts", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      render_async(view, 1_000)

      assert has_element?(view, "#discovery-card")
      assert has_element?(view, "#discovery-card .jf-discovery-label", "Job board directory")
      assert has_element?(view, "#discovery-card a.jf-board-open", "Visit job board")
      assert has_element?(view, "#discovery-card a.jf-board-open[target='_blank']")
      assert has_element?(view, "#discovery-card a.jf-board-open[rel='noopener noreferrer']")
    end

    test "the card sits among the candidate posts and never reads as a post", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      render_async(view, 1_000)

      html = render(view)

      assert html =~ ~s(id="discovery-card")
      assert html =~ ~s(id="post-nova")
      refute html =~ ~s(id="post-) <> ~s(discovery-card")
    end

    test "an anonymous visitor is offered the login instead of a save", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      render_async(view, 1_000)

      assert has_element?(view, "#discovery-card .jf-discovery-login[href='/users/log-in']")
      refute has_element?(view, "#discovery-card button", "Save")
    end

    test "a signed in visitor can save the offered board", %{conn: conn, user: user} do
      conn = signed_in(conn, user)
      {:ok, view, _html} = live(conn, "/")
      render_async(view, 1_000)

      slug = view |> element("#discovery-card") |> render() |> board_slug()

      view |> element("#discovery-card button", "Save") |> render_click()

      assert has_element?(view, "#feed-notice", "Board saved.")

      {:ok, source} = Joblite.JobBoards.get_source_by_slug(slug)
      assert {:ok, boards} = Joblite.JobBoards.saved_boards(user)
      assert Enum.any?(boards, &(&1.id == source.id))
    end

    test "a revoked session can no longer save a board for the account it owned", %{
      conn: conn,
      user: user
    } do
      token = Accounts.generate_user_session_token(user)
      conn = init_test_session(conn, %{user_token: token})
      {:ok, view, _html} = live(conn, "/")
      render_async(view, 1_000)

      slug = view |> element("#discovery-card") |> render() |> board_slug()

      :ok = Accounts.delete_user_session_token(token)

      view |> element("#discovery-card button", "Save") |> render_click()

      assert has_element?(view, "#feed-notice", "Log in to save a board.")

      {:ok, source} = Joblite.JobBoards.get_source_by_slug(slug)
      assert {:ok, boards} = Joblite.JobBoards.saved_boards(user)
      refute Enum.any?(boards, &(&1.id == source.id))
    end

    test "an unknown board id is refused", %{conn: conn, user: user} do
      conn = signed_in(conn, user)
      {:ok, view, _html} = live(conn, "/")
      render_async(view, 1_000)

      render_click(view, "boards:save", %{"id" => "00000000-0000-0000-0000-000000000000"})

      assert has_element?(view, "#feed-notice", "no longer in the directory")
    end

    test "the server cycle advances the board after thirty minutes", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      render_async(view, 1_000)
      first = view |> element("#discovery-card") |> render() |> board_slug()

      Joblite.Repo.query!(
        "UPDATE job_board_discovery_cycles SET started_at = date_trunc('second', now()) - interval '31 minutes' WHERE id = 1"
      )

      {:ok, next_view, _html} = live(conn, "/")
      render_async(next_view, 1_000)
      second = next_view |> element("#discovery-card") |> render() |> board_slug()

      assert first != second
    end

    test "the card describes the board without exposing internal coverage details", %{conn: conn} do
      Joblite.Repo.query!(
        "UPDATE job_board_discovery_cycles SET slot = 0, started_at = date_trunc('second', now()) WHERE id = 1"
      )

      {:ok, view, _html} = live(conn, "/")
      render_async(view, 3_000)

      html = render(view)

      assert has_element?(
               view,
               "#discovery-card .jf-discovery-text",
               "Find remote job listings across a range of roles and industries."
             )

      assert has_element?(view, "#discovery-card .jf-board-mode", "Remote opportunities")
      refute html =~ "Coverage confirmed"
      refute html =~ "published terms"
      refute html =~ "2026-10-21"
    end

    test "the card links to the original listing when the board published one", %{conn: conn} do
      Joblite.Repo.query!(
        "UPDATE job_board_discovery_cycles SET slot = 0, started_at = date_trunc('second', now()) WHERE id = 1"
      )

      import Ecto.Query
      {:ok, source} = Joblite.JobBoards.get_source_by_slug("jobicy")

      Joblite.Repo.update_all(from(s in Joblite.JobBoards.Source, where: s.id == ^source.id),
        set: [last_synced_at: nil]
      )

      assert {:ok, _result} =
               Joblite.JobBoards.sync_source(source,
                 transport: fn _url ->
                   {:ok,
                    %{
                      "jobs" => [
                        %{
                          "id" => "42",
                          "jobTitle" => "Elixir Engineer",
                          "url" => "https://jobicy.com/jobs/42",
                          "companyName" => "Acme",
                          "jobGeo" => "Anywhere",
                          "jobIndustry" => ["Software Engineering"],
                          "pubDate" => "2026-10-20T10:00:00Z"
                        }
                      ]
                    }}
                 end
               )

      {:ok, view, _html} = live(conn, "/")
      render_async(view, 3_000)

      assert has_element?(view, "#discovery-card[data-board='jobicy']")

      assert has_element?(
               view,
               "#discovery-card .jf-discovery-listing a[href='https://jobicy.com/jobs/42']"
             )

      assert has_element?(view, "#discovery-card .jf-discovery-listing", "Elixir Engineer")
      assert has_element?(view, "#discovery-card .jf-discovery-listing", "Jobicy")
    end
  end

  defp board_slug(html) do
    [_, slug] = Regex.run(~r/data-board="([^"]+)"/, html)
    slug
  end
end
