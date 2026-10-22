defmodule Joblite.Hiring.StageTest do
  use ExUnit.Case, async: true
  alias Joblite.Hiring.Stage

  test "a submitted application must be reviewed before it can be hired" do
    assert {:ok, :under_review} = Stage.transition(:submitted, :under_review)
    assert {:error, :invalid_transition} = Stage.transition(:submitted, :hired)
  end

  test "terminal states cannot silently reopen" do
    for terminal <- [:hired, :rejected, :withdrawn] do
      assert {:error, :invalid_transition} = Stage.transition(terminal, :under_review)
    end
  end

  test "untrusted stage values remain errors rather than new atoms" do
    assert {:ok, :interview} = Stage.cast("interview")
    assert {:error, :invalid_stage} = Stage.cast("unexpected-client-input")
    assert {:error, :invalid_stage} = Stage.cast(%{})
    assert {:error, :invalid_stage} = Stage.transition(:unknown, :hired)
  end
end
