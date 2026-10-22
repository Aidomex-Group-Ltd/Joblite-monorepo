defmodule JobliteWeb.MediaUploadTest do
  use JobliteWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  @image_path Path.expand("fixtures/sample.jpg", __DIR__)

  setup do
    File.mkdir_p!(Path.expand("../../priv/static/uploads", __DIR__))
    :ok
  end

  test "a post can be created with a durable uploaded image", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/")

    File.write!(
      @image_path,
      <<137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82, 0, 0, 0, 1, 0, 0, 0, 1, 8,
        2, 0, 0, 0, 144, 119, 83, 222, 0, 0, 0, 12, 73, 68, 65, 84, 8, 215, 99, 248, 15, 0, 1,
        193, 1, 25, 106, 159, 158, 154, 0, 0, 0, 0, 73, 69, 78, 68, 174, 66, 96, 130>>
    )

    avatar =
      file_input(view, "#feed-composer", :media, [
        %{name: "photo.jpg", content: File.read!(@image_path), type: "image/png"}
      ])

    assert render_upload(avatar, "photo.jpg") =~ "photo.jpg"

    view
    |> form("#feed-composer form", body: "Hello with image")
    |> render_submit()

    assert render_async(view, 1_000) =~ "Hello with image"
    assert has_element?(view, "#post-preview-1 img[src^='/uploads/']")
  end
end
