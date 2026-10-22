defmodule Joblite.JobBoards.Category do
  @moduledoc """
  The job category vocabulary used by the job board directory.

  A source stores only the categories its own published taxonomy confirmed.
  A board with no confirmed taxonomy keeps an empty list and is shown as
  "categories pending review" instead of an invented set.
  """

  @categories [
    :engineering,
    :design,
    :product,
    :marketing,
    :sales,
    :support,
    :data,
    :devops,
    :security,
    :qa,
    :operations,
    :finance,
    :people,
    :legal,
    :medical,
    :education,
    :writing,
    :other
  ]

  @labels %{
    engineering: "Engineering",
    design: "Design",
    product: "Product",
    marketing: "Marketing",
    sales: "Sales",
    support: "Customer support",
    data: "Data",
    devops: "DevOps",
    security: "Security",
    qa: "QA & testing",
    operations: "Operations",
    finance: "Finance",
    people: "People & HR",
    legal: "Legal",
    medical: "Healthcare",
    education: "Education",
    writing: "Writing & content",
    other: "Other"
  }

  @spec categories() :: [atom()]
  def categories, do: @categories

  @doc "The label of a category given its slug or atom."
  @spec label(atom() | String.t()) :: String.t()
  def label(category) when is_atom(category), do: Map.get(@labels, category, "Other")

  def label(slug) when is_binary(slug) do
    case category(slug) do
      nil -> "Other"
      category -> label(category)
    end
  end

  @doc "The category for a slug, or nil when the slug is unknown."
  @spec category(String.t()) :: atom() | nil
  def category(slug) when is_binary(slug) do
    Enum.find(@categories, &(Atom.to_string(&1) == slug))
  end

  @doc "True when the slug is part of the vocabulary."
  @spec valid_slug?(term()) :: boolean()
  def valid_slug?(slug) when is_binary(slug), do: not is_nil(category(slug))
  def valid_slug?(_slug), do: false

  @spec valid?(term()) :: boolean()
  def valid?(category), do: category in @categories

  @spec labels() :: %{atom() => String.t()}
  def labels, do: @labels
end
