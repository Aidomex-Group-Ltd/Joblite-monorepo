defmodule JobliteWeb.HomeLive.Uploads do
  @moduledoc """
  Durable, server-side media storage for feed preview posts.

  Files are written under `priv/static/uploads` with a random UUID name and
  served by Phoenix static serving. Only JPEG/PNG/WebP and MP4/WebM are
  accepted, with the same size limits as the client. Each stored entry carries
  an opaque id and a static `source` path; the upload is never executed and
  never stored outside the uploads directory.
  """

  @images ~w(image/jpeg image/png image/webp)
  @videos ~w(video/mp4 video/webm)
  @image_mb 10
  @video_mb 50

  @doc "LiveView upload configuration for the feed composer."
  @spec config() :: keyword()
  def config do
    [
      accept: @images ++ @videos,
      max_entries: 4,
      max_file_size: @video_mb * 1024 * 1024,
      auto_upload: true
    ]
  end

  @doc "Permitted MIME types."
  @spec allowed_types() :: [String.t()]
  def allowed_types, do: @images ++ @videos

  @doc "Validates a single uploaded entry. Returns :ok or {:error, reason}."
  @spec validate(entry :: map()) :: :ok | {:error, String.t()}
  def validate(%Phoenix.LiveView.UploadEntry{} = entry) do
    kind = kind(entry.client_type)

    cond do
      is_nil(kind) ->
        {:error, "Choose JPG, PNG, WebP, MP4, or WebM."}

      kind == :video and entry.client_size > @video_mb * 1024 * 1024 ->
        {:error, "Choose a video no larger than 50 MB."}

      kind == :image and entry.client_size > @image_mb * 1024 * 1024 ->
        {:error, "Choose a photo no larger than 10 MB."}

      entry.client_size <= 0 ->
        {:error, "Choose a non-empty file."}

      true ->
        :ok
    end
  end

  @doc "Consumes uploads and returns durable media maps."
  @spec consume(Phoenix.LiveView.Socket.t(), atom()) :: [map()]
  def consume(socket, name \\ :media) do
    uploads_dir = uploads_dir()

    Phoenix.LiveView.consume_uploaded_entries(socket, name, fn %{path: path}, entry ->
      kind = kind(entry.client_type) || :image
      ext = extension(entry.client_type)
      filename = "#{Ecto.UUID.generate()}#{ext}"
      dest = Path.join(uploads_dir, filename)
      File.cp!(path, dest)
      File.chmod!(dest, 0o644)

      {:ok,
       %{
         id: "upload-#{Ecto.UUID.generate()}",
         kind: Atom.to_string(kind),
         local: false,
         durable: true,
         source: "/uploads/#{filename}",
         thumbnail: nil,
         alt: String.slice(entry.client_name || filename, 0, 100),
         duration: nil
       }}
    end)
  end

  defp uploads_dir do
    dir = Application.app_dir(:joblite_web, "priv/static/uploads")
    File.mkdir_p!(dir)
    dir
  end

  defp kind("image/jpeg"), do: :image
  defp kind("image/png"), do: :image
  defp kind("image/webp"), do: :image
  defp kind("video/mp4"), do: :video
  defp kind("video/webm"), do: :video
  defp kind(_other), do: nil

  defp extension("image/jpeg"), do: ".jpg"
  defp extension("image/png"), do: ".png"
  defp extension("image/webp"), do: ".webp"
  defp extension("video/mp4"), do: ".mp4"
  defp extension("video/webm"), do: ".webm"
  defp extension(_other), do: ".bin"
end
