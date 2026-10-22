defmodule JobliteWeb.HomeFeedStateTest do
  use ExUnit.Case, async: true
  alias JobliteWeb.HomeLive.{FeedState, PostForm}

  defp media(id, kind \\ "image") do
    %{
      "id" => id,
      "kind" => kind,
      "type" => if(kind == "video", do: "video/webm", else: "image/jpeg"),
      "name" => "sample"
    }
  end

  test "duplicate references, excessive attachments and multiple videos are rejected" do
    item = media("local-one")
    assert {:error, _} = PostForm.parse(%{"body" => "", "media" => [item, item]})

    assert {:error, _} =
             PostForm.parse(%{"body" => "", "media" => for(i <- 1..5, do: media("local-#{i}"))})

    assert {:error, _} =
             PostForm.parse(%{
               "body" => "",
               "media" => [media("local-one", "video"), media("local-two", "video")]
             })
  end

  test "only allowed reference fields survive normalization" do
    input =
      Map.merge(media("local-one"), %{
        "source" => "javascript:alert(1)",
        "candidate_id" => "other"
      })

    assert {:ok, %{body: "Hello", media: [parsed]}} =
             PostForm.parse(%{"body" => "  Hello  ", "media" => [input]})

    assert parsed.source == nil
    refute Map.has_key?(parsed, :candidate_id)

    assert {:error, _} =
             PostForm.parse(%{"body" => "", "media" => [%{input | "id" => "not-a-local-ref"}]})
  end

  test "oversized text and non-list metadata are rejected" do
    assert {:error, _} = PostForm.parse(%{"body" => String.duplicate("x", 601), "media" => []})
    assert {:error, _} = PostForm.parse(%{"body" => "ok", "media" => %{}})
  end

  test "temporary posting is bounded without evicting earlier media references" do
    state =
      Enum.reduce(1..20, FeedState.new(), fn _, state ->
        {:ok, next} = FeedState.prepend(state, %{body: "Preview", media: []})
        next
      end)

    assert length(state.posts) == 23
    assert {:error, _} = FeedState.prepend(state, %{body: "One more", media: []})
  end
end
