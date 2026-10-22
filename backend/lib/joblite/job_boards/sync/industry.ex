defmodule Joblite.JobBoards.Sync.Industry do
  @moduledoc """
  Maps a source's own category label onto the directory's category vocabulary.

  Labels that are not part of the vocabulary are dropped rather than guessed,
  so a board keeps only the categories its own taxonomy confirmed.
  """

  @mapping %{
    "creative & design" => "design",
    "design" => "design",
    "design & creative" => "design",
    "software engineering" => "engineering",
    "engineering" => "engineering",
    "engineering & technology" => "engineering",
    "development" => "engineering",
    "developer" => "engineering",
    "information technology" => "engineering",
    "hardware engineer" => "engineering",
    "devops & infrastructure" => "devops",
    "devops" => "devops",
    "system administration" => "devops",
    "data science & analytics" => "data",
    "data" => "data",
    "data and analytics" => "data",
    "marketing & sales" => "marketing",
    "marketing" => "marketing",
    "growth" => "marketing",
    "sales" => "sales",
    "finance & accounting" => "finance",
    "finance" => "finance",
    "dev" => "engineering",
    "technical" => "engineering",
    "testing" => "qa",
    "ops" => "operations",
    "sys admin" => "devops",
    "infosec" => "security",
    "recruiter" => "people",
    "customer success" => "support",
    "customer support" => "support",
    "customer service" => "support",
    "support" => "support",
    "product & operations" => "product",
    "product" => "product",
    "operations" => "operations",
    "project management" => "operations",
    "logistics" => "operations",
    "management" => "operations",
    "administration" => "operations",
    "qa & testing" => "qa",
    "cybersecurity" => "security",
    "security" => "security",
    "human resources" => "people",
    "people" => "people",
    "legal & compliance" => "legal",
    "legal" => "legal",
    "healthcare & medical" => "medical",
    "medical" => "medical",
    "healthcare" => "medical",
    "education & e-learning" => "education",
    "education" => "education",
    "teaching" => "education",
    "editorial & content" => "writing",
    "content creator" => "writing",
    "writing" => "writing",
    "content writing" => "writing",
    "other" => "other",
    "all others" => "other"
  }

  @doc "Returns the directory category slug for a source label, or nil."
  @spec normalize(String.t() | nil) :: String.t() | nil
  def normalize(nil), do: nil

  def normalize(label) when is_binary(label) do
    Map.get(@mapping, String.downcase(String.trim(label)))
  end
end
