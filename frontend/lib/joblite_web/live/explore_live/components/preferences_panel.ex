defmodule JobliteWeb.ExploreLive.Components.PreferencesPanel do
  @moduledoc """
  The discovery preferences of the account.

  The panel edits the region, the categories and the worldwide-only flag that
  rank the boards in the feed. The values are the slugs the core published, so
  the form never offers a category the core does not know. The preferences
  belong to the account; an anonymous visitor is offered the login instead.
  """
  use Phoenix.Component

  alias Joblite.JobBoards.Category
  alias Joblite.JobBoards.Region

  attr(:preferences, :map, default: nil)
  attr(:options, :map, required: true)
  attr(:signed_in, :boolean, default: false)
  attr(:registry_available, :boolean, default: true)

  def preferences_panel(assigns) do
    preferences = assigns.preferences

    assigns =
      assigns
      |> assign(:summary, summary(preferences))
      |> assign(:region, region_slug(preferences))
      |> assign(:categories, categories(preferences))

    ~H"""
    <section id="explore-preferences" class="jf-preferences">
      <h2>Discovery preferences</h2>

      <p :if={!@signed_in} class="jf-preferences-hint">
        <a href="/users/log-in">Log in</a> to tell Joblite which region and categories the feed
        should prefer.
      </p>

      <p :if={@signed_in and !@registry_available} class="jf-preferences-hint jf-preferences-error">
        Your preferences could not be read. The registry is unavailable right now.
      </p>

      <p :if={@signed_in and @registry_available} class="jf-preferences-hint" data-preference-summary>
        {@summary}
      </p>

      <form
        :if={@signed_in and @registry_available}
        id="explore-preferences-form"
        phx-submit="preferences:save"
      >
        <label class="jf-field">
          <span class="jf-field-label">Region</span>
          <select name="region">
            <option value="">Every region</option>
            <option
              :for={region <- @options.regions}
              value={region.value}
              selected={@region == region.value}
            >
              {region.label}
            </option>
          </select>
        </label>

        <details class="jf-preferences-categories">
          <summary>Categories</summary>
          <div class="jf-preferences-grid">
            <label :for={category <- @options.categories} class="jf-check">
              <input
                type="checkbox"
                name="categories[]"
                value={category.value}
                checked={category.value in @categories}
              />
              <span>{category.label}</span>
            </label>
          </div>
        </details>

        <label class="jf-check">
          <input
            type="checkbox"
            name="worldwide_only"
            value="true"
            checked={@preferences != nil and @preferences.worldwide_only}
          />
          <span>Worldwide remote only</span>
        </label>

        <div class="jf-preferences-actions">
          <button type="submit">Save preferences</button>
          <button type="button" phx-click="preferences:reset">Reset</button>
        </div>
      </form>
    </section>
    """
  end

  defp summary(nil), do: "No preference saved yet."

  defp summary(preferences) do
    [
      region_label(preferences.region),
      category_label(preferences.categories),
      worldwide_label(preferences.worldwide_only)
    ]
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.join(" · ")
    |> case do
      "" -> "No preference saved yet."
      text -> text
    end
  end

  defp region_label(nil), do: nil
  defp region_label(region), do: Region.label(region)

  defp region_slug(nil), do: nil
  defp region_slug(%{region: nil}), do: nil
  defp region_slug(%{region: region}), do: Atom.to_string(region)

  defp categories(nil), do: []
  defp categories(%{categories: categories}), do: categories || []

  defp category_label([]), do: nil
  defp category_label(categories), do: Enum.map_join(categories, ", ", &Category.label/1)

  defp worldwide_label(false), do: nil
  defp worldwide_label(true), do: "Worldwide remote only"
end
