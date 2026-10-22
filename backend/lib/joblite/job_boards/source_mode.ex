defmodule Joblite.JobBoards.SourceMode do
  @moduledoc """
  Pure permission rules for job board sources.

  The mode of a source is the only switch that decides what Joblite may do
  with it:

    * `:permitted_live_aggregation` - the source published terms that allow
      republication; listings may be imported, subject to the source's
      attribution, canonical link and synchronization rules.
    * `:directory_only` - the source stays an outbound link. Its listings are
      never imported or displayed.
    * `:permission_pending` - written approval is requested but not recorded,
      so the source stays an outbound link.
    * `:temporarily_disabled` - the source is neither imported nor promoted in
      the feed.

  Public API or RSS availability alone never grants republication rights.
  """

  @modes [
    :permitted_live_aggregation,
    :directory_only,
    :permission_pending,
    :temporarily_disabled
  ]

  @access_methods [:api, :rss, :partner_agreement, :official_link]

  @remote_eligibilities [:worldwide, :regional, :country_restricted, :unknown]

  @labels %{
    permitted_live_aggregation: "Feed candidate",
    directory_only: "Directory only",
    permission_pending: "Permission pending",
    temporarily_disabled: "Temporarily disabled"
  }

  @spec modes() :: [atom()]
  def modes, do: @modes

  @spec access_methods() :: [atom()]
  def access_methods, do: @access_methods

  @spec remote_eligibilities() :: [atom()]
  def remote_eligibilities, do: @remote_eligibilities

  @spec label(atom()) :: String.t()
  def label(mode), do: Map.get(@labels, mode, "Unknown status")

  @spec valid_mode?(term()) :: boolean()
  def valid_mode?(mode), do: mode in @modes

  @spec valid_access_method?(term()) :: boolean()
  def valid_access_method?(method), do: method in @access_methods

  @spec valid_remote_eligibility?(term()) :: boolean()
  def valid_remote_eligibility?(value), do: value in @remote_eligibilities

  @doc "True only for sources whose terms allow republication."
  @spec aggregate?(term()) :: boolean()
  def aggregate?(mode), do: mode == :permitted_live_aggregation

  @doc "True for sources that must remain outbound links."
  @spec link_only?(term()) :: boolean()
  def link_only?(mode), do: mode in [:directory_only, :permission_pending]

  @doc "True for sources that are switched off."
  @spec disabled?(term()) :: boolean()
  def disabled?(mode), do: mode == :temporarily_disabled

  @doc "True for sources that may appear as a labelled discovery card."
  @spec promotable?(term()) :: boolean()
  def promotable?(mode),
    do: mode in [:permitted_live_aggregation, :directory_only, :permission_pending]

  @spec promotable_modes() :: [atom()]
  def promotable_modes, do: Enum.filter(@modes, &promotable?/1)
end
