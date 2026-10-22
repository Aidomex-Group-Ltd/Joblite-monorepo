defmodule Joblite.JobBoardsTest do
  use Joblite.DataCase, async: true

  alias Joblite.Accounts
  alias Joblite.JobBoards

  setup do
    {:ok, user} =
      Accounts.register_user(%{email: "reader@example.com", password: "correct-horse-1"})

    %{user: user}
  end

  defp source_id(slug) do
    {:ok, source} = JobBoards.get_source_by_slug(slug)
    source.id
  end

  describe "directory/1" do
    test "lists every registered board with its permission mode" do
      assert {:ok, boards} = JobBoards.directory()

      slugs = Enum.map(boards, & &1.slug)
      assert "remote-ok" in slugs
      assert "jobicy" in slugs
      assert "himalayas" in slugs
      assert "remotive" in slugs

      remote_ok = Enum.find(boards, &(&1.slug == "remote-ok"))
      assert remote_ok.mode == :permitted_live_aggregation
      assert remote_ok.mode_label == "Feed candidate"

      remotive = Enum.find(boards, &(&1.slug == "remotive"))
      assert remotive.mode == :directory_only
      assert remotive.mode_label == "Directory only"
    end

    test "a board without a confirmed taxonomy keeps its categories empty" do
      assert {:ok, boards} = JobBoards.directory()

      for board <- boards do
        assert is_list(board.categories)
        assert is_list(board.regions)
      end
    end

    test "search matches the board name" do
      assert {:ok, boards} = JobBoards.directory(%{text: "jobicy"})

      assert Enum.map(boards, & &1.slug) == ["jobicy"]
    end

    test "search matches a country a board covers" do
      assert {:ok, boards} = JobBoards.directory(%{text: "Poland"})

      assert Enum.map(boards, & &1.slug) == ["no-fluff-jobs"]
    end

    test "an empty search returns the whole directory" do
      assert {:ok, boards} = JobBoards.directory(%{text: "  "})
      assert length(boards) >= 9
    end

    test "a region filter keeps the boards that cover that region" do
      assert {:ok, boards} = JobBoards.directory(%{region: :europe})
      slugs = Enum.map(boards, & &1.slug)

      assert "arbeitnow" in slugs
      assert "jobget" not in slugs

      for board <- boards do
        assert "europe" in board.regions or "global" in board.regions
      end
    end

    test "the worldwide filter keeps only the boards open to every country" do
      assert {:ok, boards} = JobBoards.directory(%{worldwide_only: true})
      slugs = Enum.map(boards, & &1.slug)

      assert "remote-ok" in slugs
      assert "jobget" not in slugs
      assert "no-fluff-jobs" not in slugs
    end
  end

  describe "saved boards" do
    test "saving a board keeps it on the account's list", %{user: user} do
      id = source_id("remote-ok")

      assert {:ok, _saved} = JobBoards.save_board(user, id)
      assert {:ok, boards} = JobBoards.saved_boards(user)

      assert Enum.map(boards, & &1.slug) == ["remote-ok"]
    end

    test "saving the same board twice keeps one entry", %{user: user} do
      id = source_id("remote-ok")

      assert {:ok, _saved} = JobBoards.save_board(user, id)
      assert {:ok, _saved} = JobBoards.save_board(user, id)

      assert {:ok, boards} = JobBoards.saved_boards(user)
      assert length(boards) == 1
    end

    test "unsaving removes the board from the list", %{user: user} do
      id = source_id("remote-ok")
      {:ok, _saved} = JobBoards.save_board(user, id)

      assert :ok = JobBoards.unsave_board(user, id)
      assert {:ok, boards} = JobBoards.saved_boards(user)
      assert boards == []
    end

    test "saving an unknown board fails", %{user: user} do
      assert {:error, :unknown_source} = JobBoards.save_board(user, Ecto.UUID.generate())
    end
  end

  describe "dismissed boards" do
    test "a dismissed board leaves the discovery cards", %{user: user} do
      id = source_id("jobicy")
      assert {:ok, _dismissal} = JobBoards.dismiss_board(user, id)

      assert MapSet.member?(JobBoards.dismissed_source_ids(user), id)

      cards = JobBoards.discovery_cards(user)
      refute Enum.any?(cards, &(&1.id == id))
    end

    test "revisiting a dismissed board brings it back", %{user: user} do
      id = source_id("jobicy")
      {:ok, _dismissal} = JobBoards.dismiss_board(user, id)

      assert :ok = JobBoards.revisit_board(user, id)
      refute MapSet.member?(JobBoards.dismissed_source_ids(user), id)

      cards = JobBoards.discovery_cards(user)
      assert Enum.any?(cards, &(&1.id == id))
    end

    test "an expired dismissal no longer hides the board", %{user: user} do
      id = source_id("jobicy")
      {:ok, _dismissal} = JobBoards.dismiss_board(user, id)

      Repo.update_all(Joblite.JobBoards.Dismissal,
        set: [expires_at: DateTime.add(DateTime.utc_now(), -1, :hour)]
      )

      refute MapSet.member?(JobBoards.dismissed_source_ids(user), id)
    end

    test "the dismissed boards are listed so they can be brought back", %{user: user} do
      id = source_id("jobicy")
      {:ok, _dismissal} = JobBoards.dismiss_board(user, id)

      assert {:ok, boards} = JobBoards.dismissed_boards(user)
      assert Enum.map(boards, & &1.slug) == ["jobicy"]
      assert Enum.find(boards, &(&1.slug == "jobicy")).mode == :permitted_live_aggregation
    end

    test "the dismissed boards of another account stay hidden", %{user: user} do
      id = source_id("jobicy")
      {:ok, _dismissal} = JobBoards.dismiss_board(user, id)

      assert {:ok, boards} = JobBoards.dismissed_boards(user)
      assert boards != []

      {:ok, other} =
        Accounts.register_user(%{email: "other-reader@example.com", password: "correct-horse-1"})

      assert {:ok, boards} = JobBoards.dismissed_boards(other)
      assert boards == []
    end
  end

  describe "preferences" do
    test "an account without preferences gets neutral defaults", %{user: user} do
      assert {:ok, preferences} = JobBoards.preferences(user)

      assert preferences.region == nil
      assert preferences.categories == []
      refute preferences.worldwide_only
    end

    test "saved preferences are read back", %{user: user} do
      assert {:ok, _preference} =
               JobBoards.save_preferences(user, %{
                 region: :europe,
                 categories: ["engineering"],
                 worldwide_only: true
               })

      assert {:ok, preferences} = JobBoards.preferences(user)
      assert preferences.region == :europe
      assert preferences.categories == ["engineering"]
      assert preferences.worldwide_only
    end

    test "preferences rank the matching board first", %{user: user} do
      {:ok, _preference} = JobBoards.save_preferences(user, %{categories: ["finance"]})

      [card | _rest] = JobBoards.discovery_cards(user)
      assert card.mode == :permitted_live_aggregation
    end

    test "saving empty preferences clears the stored ones", %{user: user} do
      {:ok, _preference} =
        JobBoards.save_preferences(user, %{
          region: :europe,
          categories: ["engineering"],
          worldwide_only: true
        })

      assert {:ok, _cleared} = JobBoards.save_preferences(user, %{})

      assert {:ok, preferences} = JobBoards.preferences(user)
      assert preferences.region == nil
      assert preferences.categories == []
      refute preferences.worldwide_only
    end

    test "the preferences are updated instead of inserted twice", %{user: user} do
      {:ok, _first} = JobBoards.save_preferences(user, %{region: :europe})
      {:ok, _second} = JobBoards.save_preferences(user, %{region: :africa})

      assert {:ok, preferences} = JobBoards.preferences(user)
      assert preferences.region == :africa
    end

    test "an unknown region is refused instead of stored", %{user: user} do
      assert {:error, changeset} = JobBoards.save_preferences(user, %{region: "atlantis"})
      assert %{region: ["is invalid"]} = errors_on(changeset)
    end

    test "an unknown category is refused instead of stored", %{user: user} do
      assert {:error, changeset} =
               JobBoards.save_preferences(user, %{categories: ["astrology"]})

      assert %{categories: [message]} = errors_on(changeset)
      assert message =~ "astrology"
    end
  end

  describe "discovery_cards/2" do
    test "returns at most the requested number of cards" do
      assert [card] = JobBoards.discovery_cards(nil, limit: 1)
      assert card.mode in [:permitted_live_aggregation, :directory_only, :permission_pending]
    end

    test "skips the boards already shown in the session" do
      assert [first] = JobBoards.discovery_cards(nil, limit: 1)
      assert [second] = JobBoards.discovery_cards(nil, limit: 1, exclude_source_ids: [first.id])
      assert second.id != first.id
    end

    test "an offset rotates the board a session sees next" do
      assert [first] = JobBoards.discovery_cards(nil, limit: 1)
      assert [second] = JobBoards.discovery_cards(nil, limit: 1, offset: 1)
      assert second.id != first.id
    end

    test "returns nothing when every promotable board was already shown" do
      {:ok, boards} = JobBoards.directory()
      ids = Enum.map(boards, & &1.id)

      assert JobBoards.discovery_cards(nil, limit: 1, exclude_source_ids: ids) == []
    end

    test "a card never carries a listing for a link only board" do
      assert [card] = JobBoards.discovery_cards(nil, limit: 1, exclude_source_ids: [])
      assert card.listing == nil or card.mode == :permitted_live_aggregation
    end
  end
end
