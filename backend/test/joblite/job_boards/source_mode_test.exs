defmodule Joblite.JobBoards.SourceModeTest do
  use ExUnit.Case, async: true

  alias Joblite.JobBoards.SourceMode

  describe "permission rules" do
    test "only a source whose terms allow aggregation may be imported" do
      assert SourceMode.aggregate?(:permitted_live_aggregation)
      refute SourceMode.aggregate?(:directory_only)
      refute SourceMode.aggregate?(:permission_pending)
      refute SourceMode.aggregate?(:temporarily_disabled)
    end

    test "a directory only source and a pending permission source stay outbound links" do
      assert SourceMode.link_only?(:directory_only)
      assert SourceMode.link_only?(:permission_pending)
      refute SourceMode.link_only?(:permitted_live_aggregation)
    end

    test "a temporarily disabled source is neither imported nor promoted" do
      assert SourceMode.disabled?(:temporarily_disabled)
      refute SourceMode.promotable?(:temporarily_disabled)
      refute SourceMode.aggregate?(:temporarily_disabled)
      refute SourceMode.link_only?(:temporarily_disabled)
    end

    test "every enabled mode may be shown as a labelled card" do
      assert SourceMode.promotable?(:permitted_live_aggregation)
      assert SourceMode.promotable?(:directory_only)
      assert SourceMode.promotable?(:permission_pending)
    end

    test "the promotable modes exclude the disabled one" do
      refute :temporarily_disabled in SourceMode.promotable_modes()
      assert length(SourceMode.promotable_modes()) == 3
    end
  end

  describe "labels and validators" do
    test "every mode has a human label" do
      for mode <- SourceMode.modes() do
        assert SourceMode.label(mode) != "Unknown status"
      end
    end

    test "validators accept only known values" do
      assert SourceMode.valid_mode?(:directory_only)
      refute SourceMode.valid_mode?(:made_up_mode)

      assert SourceMode.valid_access_method?(:api)
      refute SourceMode.valid_access_method?(:scraping)

      assert SourceMode.valid_remote_eligibility?(:worldwide)
      refute SourceMode.valid_remote_eligibility?(:anywhere)
    end
  end
end
