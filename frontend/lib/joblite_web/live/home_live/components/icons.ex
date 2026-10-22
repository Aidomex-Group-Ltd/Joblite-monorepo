defmodule JobliteWeb.HomeLive.Components.Icons do
  @moduledoc "A small inline SVG vocabulary used by the feed components."
  use Phoenix.Component

  @paths %{
    "home" => "M3 10l9-7 9 7v11h-6v-7H9v7H3z",
    "bookmark" => "M6 3h12v18l-6-4-6 4z",
    "user" => "M20 21v-2a8 8 0 0 0-16 0v2 M12 3a4 4 0 1 0 0 8 4 4 0 0 0 0-8",
    "plus" => "M12 5v14 M5 12h14",
    "edit" => "M15 4l5 5 M4 20l5-1L21 7l-5-5L4 14z",
    "heart" =>
      "M20.8 4.6a5.5 5.5 0 0 0-7.8 0L12 5.7l-1.1-1.1a5.5 5.5 0 0 0-7.8 7.8L12 21l8.8-8.6a5.5 5.5 0 0 0 0-7.8z",
    "reply" =>
      "M21 11.5a8.4 8.4 0 0 1-.9 3.8 8.5 8.5 0 0 1-7.6 4.7 8.4 8.4 0 0 1-3.8-.9L3 21l1.9-5.7a8.4 8.4 0 0 1-.9-3.8 8.5 8.5 0 0 1 4.7-7.6 8.4 8.4 0 0 1 3.8-.9h.5a8.5 8.5 0 0 1 8 8z",
    "image" => "M3 3h18v18H3z M3 16l5-5 4 4 3-3 6 6 M15 6h.01",
    "video" => "M3 5h12v14H3z M15 10l6-4v12l-6-4",
    "play" => "M8 5l12 7-12 7z",
    "close" => "M6 6l12 12 M6 18L18 6",
    "left" => "M14 6l-6 6 6 6",
    "right" => "M10 6l6 6-6 6",
    "expand" => "M8 3H3v5 M16 3h5v5 M21 16v5h-5 M8 21H3v-5",
    "briefcase" => "M3 7h18v14H3z M8 7V3h8v4 M3 12h18 M10 12v3h4v-3",
    "compass" => "M12 2a10 10 0 1 0 0 20 10 10 0 0 0 0-20 M15.5 8.5l-2.2 5.3-5.3 2.2 2.2-5.3z",
    "external" => "M14 4h6v6 M20 4l-9 9 M18 14v5a1 1 0 0 1-1 1H5a1 1 0 0 1-1-1V7a1 1 0 0 1 1-1h5"
  }
  attr(:name, :string, required: true)

  def icon(assigns) do
    assigns = assign(assigns, :path, Map.fetch!(@paths, assigns.name))

    ~H"""
    <svg
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      stroke-width="1.7"
      stroke-linecap="round"
      stroke-linejoin="round"
      aria-hidden="true"
    ><path d={@path} /></svg>
    """
  end
end
