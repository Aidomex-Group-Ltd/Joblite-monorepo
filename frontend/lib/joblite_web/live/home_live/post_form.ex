defmodule JobliteWeb.HomeLive.PostForm do
  @moduledoc "Validates preview text and accepts either durable server uploads or opaque browser references."
  @types %{"image" => ~w(image/jpeg image/png image/webp), "video" => ~w(video/mp4 video/webm)}

  @spec parse(term(), [map()]) :: {:ok, map()} | {:error, String.t()}
  def parse(params, uploaded \\ [])

  def parse(%{"body" => body, "media" => media}, uploaded)
      when is_binary(body) and is_list(media) do
    body = String.trim(body)
    combined = uploaded ++ media

    cond do
      String.length(body) > 600 -> {:error, "Keep your post to 600 characters."}
      length(combined) > 4 -> {:error, "Choose up to four attachments."}
      body == "" and combined == [] -> {:error, "Add some text or media first."}
      true -> parse_media(body, combined)
    end
  end

  def parse(%{"body" => body, "media" => media}, uploaded)
      when is_binary(body) and media in [nil, ""] do
    parse(%{"body" => body, "media" => []}, uploaded)
  end

  def parse(%{"body" => body, "media" => _media}, _uploaded) when is_binary(body) do
    {:error, "The post could not be read. Try again."}
  end

  def parse(%{"body" => body} = params, uploaded) when is_binary(body) do
    if Map.has_key?(params, "media") do
      {:error, "The post could not be read. Try again."}
    else
      parse(%{"body" => body, "media" => []}, uploaded)
    end
  end

  def parse(_params, _uploaded), do: {:error, "The post could not be read. Try again."}

  defp parse_media(body, entries) do
    parsed = Enum.map(entries, &parse_entry/1)

    cond do
      :error in parsed ->
        {:error, "One of the media references is invalid. Choose the file again."}

      Enum.count(parsed, &(&1.kind == "video")) > 1 ->
        {:error, "Choose one video per post."}

      length(Enum.uniq_by(parsed, & &1.id)) != length(parsed) ->
        {:error, "Remove duplicate attachments."}

      true ->
        {:ok, %{body: body, media: parsed}}
    end
  end

  defp parse_entry(entry) when is_map(entry) do
    durable = Map.get(entry, :durable) || Map.get(entry, "durable")

    if durable do
      parse_durable(entry)
    else
      parse_local(entry)
    end
  end

  defp parse_entry(_entry), do: :error

  defp parse_durable(entry) do
    id = entry[:id] || entry["id"]
    kind = entry[:kind] || entry["kind"]
    source = entry[:source] || entry["source"]
    alt = entry[:alt] || entry["alt"] || ""

    if valid_durable?(id, kind, source, alt) do
      %{
        id: id,
        kind: kind,
        local: false,
        durable: true,
        source: source,
        thumbnail: entry[:thumbnail] || entry["thumbnail"],
        alt: alt,
        duration: entry[:duration] || entry["duration"]
      }
    else
      :error
    end
  end

  defp valid_durable?(id, kind, source, alt)
       when is_binary(id) and is_binary(source) and is_binary(alt) do
    kind in ~w(image video) and String.starts_with?(source, "/uploads/") and
      String.length(id) <= 80 and String.length(alt) <= 100
  end

  defp valid_durable?(_id, _kind, _source, _alt), do: false

  defp parse_local(%{"id" => id, "kind" => kind, "type" => type, "name" => name}) do
    local_media(id, kind, type, name, nil)
  end

  defp parse_local(%{id: id, kind: kind, type: type, name: name} = entry) do
    local_media(id, kind, type, name, entry[:thumbnail] || entry["thumbnail"])
  end

  defp parse_local(_entry), do: :error

  defp local_media(id, kind, type, name, thumbnail) do
    if valid_local?(id, kind, type, name) do
      %{
        id: id,
        kind: kind,
        local: true,
        durable: false,
        source: nil,
        thumbnail: thumbnail,
        alt: name,
        duration: nil
      }
    else
      :error
    end
  end

  defp valid_local?(id, kind, type, name)
       when is_binary(id) and is_binary(kind) and is_binary(type) and is_binary(name) do
    String.length(id) <= 80 and Regex.match?(~r/^local-[a-zA-Z0-9-]+$/, id) and
      type in Map.get(@types, kind, []) and String.length(name) in 1..100
  end

  defp valid_local?(_id, _kind, _type, _name), do: false
end
