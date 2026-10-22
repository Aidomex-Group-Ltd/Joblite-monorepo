defmodule Joblite.Repo.Migrations.SeedJobBoardSources do
  @moduledoc """
  Seeds the job board source registry.

  Every row records what the board itself published when it was checked on
  2026-10-21. A row that could not be confirmed keeps unknown values instead
  of invented ones. `source_mode` carries the permission decision:

    * `permitted_live_aggregation` - the board published terms that allow
      republication with attribution and a canonical link (Remote OK, Jobicy).
    * `permission_pending` - written approval is requested but not recorded
      (Himalayas).
    * `directory_only` - the board stays an outbound link (Remotive,
      We Work Remotely, Working Nomads, JobGet, Arbeitnow, No Fluff Jobs).

  `access_method` records how the board publishes its data. It never grants a
  right on its own: the mode decides what Joblite may do with the board.
  """

  use Ecto.Migration

  alias Joblite.JobBoards.Source

  @verified_at ~U[2026-10-21 12:00:00Z]

  def change do
    repo().insert_all(Source, rows(), on_conflict: :nothing)
  end

  defp rows do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    Enum.map(sources(), fn source ->
      source
      |> Map.put(:last_verified_at, @verified_at)
      |> Map.put(:inserted_at, now)
      |> Map.put(:updated_at, now)
    end)
  end

  defp sources do
    [
      %{
        slug: "remote-ok",
        name: "Remote OK",
        official_url: "https://remoteok.com/",
        regions: ["global", "africa", "europe", "north_america", "latin_america", "asia_pacific_mena"],
        countries: [],
        coverage_status: :confirmed,
        remote_eligibility: :worldwide,
        categories: [
          "engineering",
          "design",
          "marketing",
          "sales",
          "support",
          "finance",
          "medical",
          "education",
          "operations",
          "writing",
          "security",
          "people"
        ],
        source_mode: :permitted_live_aggregation,
        access_method: :api,
        attribution_required: true,
        attribution_text:
          "Remote OK - link back to the Remote OK listing URL with a follow link and mention Remote OK as the source.",
        canonical_link_required: true,
        permitted_sync_interval_minutes: 60,
        sync_interval_note:
          "The API terms state the attribution and link-back duties but no interval, so Joblite caps a pass at one per hour.",
        feed_freshness: :live,
        health_status: :unverified,
        status_note:
          "Terms read from the live API payload on 2026-10-21: the API may be used when the consumer links back to the Remote OK listing URL with a follow link and mentions Remote OK as the source, and the Remote OK logo may not be reused without written permission. The board publishes no synchronization interval, so Joblite caps a pass at one per hour. The board has no category taxonomy of its own; the categories below are the ones Joblite derives from the tags the board publishes with every listing. Coverage varies per listing, so the registry keeps the region coverage only."
      },
      %{
        slug: "jobicy",
        name: "Jobicy",
        official_url: "https://jobicy.com/",
        regions: ["africa", "europe", "north_america", "asia_pacific_mena"],
        countries: [],
        coverage_status: :confirmed,
        remote_eligibility: :worldwide,
        categories: [
          "engineering",
          "devops",
          "design",
          "data",
          "marketing",
          "sales",
          "finance",
          "support",
          "product",
          "operations",
          "legal",
          "medical",
          "education",
          "people",
          "writing",
          "security",
          "qa"
        ],
        source_mode: :permitted_live_aggregation,
        access_method: :api,
        attribution_required: true,
        attribution_text:
          "Jobicy - credit Jobicy and link to the Jobicy listing URL.",
        canonical_link_required: true,
        permitted_sync_interval_minutes: 60,
        sync_interval_note:
          "The developer page states that a new automated pass must not run more than once per hour.",
        feed_freshness: :live,
        health_status: :unverified,
        status_note:
          "Fair use terms read on 2026-10-21 from the developer page: Jobicy listings may be used in a product without individual permission when Jobicy stays the original source, the canonical Jobicy listing URL is preserved, the listings are not presented as the product's own postings and the source attribution is not removed. The same page states that a new automated pass must not start more than once per hour. The published location taxonomy is USA, Canada, Europe, UK, Germany, EMEA and APAC."
      },
      %{
        slug: "himalayas",
        name: "Himalayas",
        official_url: "https://himalayas.app/",
        regions: ["global", "africa", "europe", "north_america", "latin_america", "asia_pacific_mena"],
        countries: [],
        coverage_status: :confirmed,
        remote_eligibility: :worldwide,
        categories: [],
        source_mode: :permission_pending,
        access_method: :api,
        attribution_required: true,
        attribution_text:
          "Himalayas - name Himalayas as the source with a visible link to the Himalayas job or to himalayas.app, and keep the Apply action on the application link the API supplies.",
        canonical_link_required: true,
        permitted_sync_interval_minutes: nil,
        sync_interval_note: "No synchronization is permitted while written permission is pending.",
        feed_freshness: :daily,
        health_status: :unverified,
        status_note:
          "The API conditions read on 2026-10-21 in the terms of use allow showing Himalayas jobs on your own site, website or app without asking first, but they forbid passing the jobs on to third parties such as other job boards, aggregators, job search engines, Google Jobs or LinkedIn Jobs. Written permission for redistribution is not recorded, so the board stays an outbound link until it is. The board publishes a free-form category per listing instead of a fixed taxonomy, so no category list is recorded here."
      },
      %{
        slug: "remotive",
        name: "Remotive",
        official_url: "https://remotive.com/remote-jobs",
        regions: ["global", "africa", "europe", "north_america", "latin_america", "asia_pacific_mena"],
        countries: [],
        coverage_status: :confirmed,
        remote_eligibility: :worldwide,
        categories: [
          "engineering",
          "design",
          "marketing",
          "sales",
          "support",
          "data",
          "devops",
          "finance",
          "people",
          "qa",
          "operations",
          "product",
          "writing",
          "legal",
          "medical",
          "education",
          "other"
        ],
        source_mode: :directory_only,
        access_method: :api,
        attribution_required: true,
        attribution_text:
          "Remotive - link back to the Remotive listing URL and mention Remotive as a source.",
        canonical_link_required: true,
        permitted_sync_interval_minutes: nil,
        sync_interval_note:
          "The board advises no more than four passes a day and blocks more than two requests a minute, so aggregation stays switched off.",
        feed_freshness: :daily,
        health_status: :unverified,
        status_note:
          "The API legal notice read on 2026-10-21 asks for a link back and a source mention and forbids submitting Remotive jobs to third party job sites, so the registry keeps this source link-only. The API documentation read the same day advises no more than four passes a day and blocks more than two requests a minute. The board states that its listings are delayed by 24 hours and publishes its own category and location taxonomy."
      },
      %{
        slug: "we-work-remotely",
        name: "We Work Remotely",
        official_url: "https://weworkremotely.com/remote-jobs",
        regions: ["global", "africa", "europe", "north_america", "asia_pacific_mena"],
        countries: [],
        coverage_status: :confirmed,
        remote_eligibility: :worldwide,
        categories: [
          "engineering",
          "design",
          "devops",
          "finance",
          "product",
          "support",
          "sales",
          "marketing",
          "other"
        ],
        source_mode: :directory_only,
        access_method: :rss,
        attribution_required: false,
        attribution_text: nil,
        canonical_link_required: false,
        permitted_sync_interval_minutes: nil,
        sync_interval_note: "No synchronization is permitted for this source.",
        feed_freshness: :hourly,
        health_status: :unverified,
        status_note:
          "The feed information page could not be read from this host on 2026-10-21 because the request was refused, so no attribution duty and no aggregation right are recorded for this source and the board stays an outbound link until its feed terms are read. The board labels its listings worldwide, North America, EMEA or Asia, and its feed carries a 60 minute TTL."
      },
      %{
        slug: "working-nomads",
        name: "Working Nomads",
        official_url: "https://www.workingnomads.com/jobs",
        regions: ["global", "africa", "europe", "north_america", "latin_america", "asia_pacific_mena"],
        countries: [],
        coverage_status: :confirmed,
        remote_eligibility: :worldwide,
        categories: [
          "operations",
          "support",
          "engineering",
          "design",
          "education",
          "finance",
          "legal",
          "medical",
          "people",
          "marketing",
          "sales",
          "devops",
          "writing"
        ],
        source_mode: :directory_only,
        access_method: :api,
        attribution_required: false,
        attribution_text: nil,
        canonical_link_required: false,
        permitted_sync_interval_minutes: nil,
        sync_interval_note: "No synchronization is permitted for this source.",
        feed_freshness: :daily,
        health_status: :unverified,
        status_note:
          "A public JSON endpoint exists at workingnomads.com/api/exposed_jobs/. The terms of service read on 2026-10-21, last updated 11 March 2025, neither grant nor forbid republication and forbid using the service to build a competitive product or service, so the registry keeps this source link-only. The board publishes region pages for North America, Latin America, Europe, the Middle East, Africa and APAC."
      },
      %{
        slug: "jobget",
        name: "JobGet",
        official_url: "https://www.jobget.com/jobs/search",
        regions: ["north_america"],
        countries: ["United States"],
        coverage_status: :confirmed,
        remote_eligibility: :country_restricted,
        categories: ["finance", "operations", "design", "support", "medical", "sales", "security"],
        source_mode: :directory_only,
        access_method: :official_link,
        attribution_required: false,
        attribution_text: nil,
        canonical_link_required: false,
        permitted_sync_interval_minutes: nil,
        sync_interval_note: "No synchronization is permitted for this source.",
        feed_freshness: :unknown,
        health_status: :unverified,
        status_note:
          "The terms of service read on 2026-10-21, updated 3 April 2025, forbid copying, aggregating, republishing or compiling the content into a collection, database or directory without express prior written permission, forbid systematically retrieving content and forbid any automated access. The board publishes its jobs for United States locations and offers no public feed licence, so the registry keeps this source link-only."
      },
      %{
        slug: "arbeitnow",
        name: "Arbeitnow",
        official_url: "https://www.arbeitnow.com/",
        regions: ["europe"],
        countries: ["Germany", "United Kingdom", "France", "Switzerland", "Netherlands"],
        coverage_status: :confirmed,
        remote_eligibility: :regional,
        categories: [
          "engineering",
          "design",
          "devops",
          "data",
          "support",
          "marketing",
          "product",
          "qa",
          "operations"
        ],
        source_mode: :directory_only,
        access_method: :api,
        attribution_required: true,
        attribution_text: "Arbeitnow - provide a link back to Arbeitnow.com.",
        canonical_link_required: true,
        permitted_sync_interval_minutes: nil,
        sync_interval_note: "No synchronization is permitted for this source.",
        feed_freshness: :hourly,
        health_status: :unverified,
        status_note:
          "The public API terms read on 2026-10-21 ask for a link back to Arbeitnow.com and state that the permission to use the API may be revoked at any time, so the registry keeps this source link-only. The API states that the jobs are updated every hour. The board publishes editions for Germany, the United Kingdom, France, Switzerland and the Netherlands."
      },
      %{
        slug: "no-fluff-jobs",
        name: "No Fluff Jobs",
        official_url: "https://nofluffjobs.com/",
        regions: ["europe"],
        countries: ["Poland"],
        coverage_status: :unknown,
        remote_eligibility: :country_restricted,
        categories: ["engineering", "marketing", "support", "sales", "people", "other"],
        source_mode: :directory_only,
        access_method: :official_link,
        attribution_required: false,
        attribution_text: nil,
        canonical_link_required: false,
        permitted_sync_interval_minutes: nil,
        sync_interval_note: "No synchronization is permitted for this source.",
        feed_freshness: :unknown,
        health_status: :unverified,
        status_note:
          "The terms page could not be read as text from this host on 2026-10-21 because the page is rendered by script, and no feed licence is published, so written permission would be needed and the registry keeps this source link-only. The job pages confirmed on 2026-10-21 are published for Poland; the other national editions of the board were not confirmed from this host, so the coverage stays pending review."
      }
    ]
  end
end
