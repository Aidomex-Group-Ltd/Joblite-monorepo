defmodule Joblite.Hiring.Stage do
  @moduledoc """
  Pure application-stage rules. This module does not authorize actors or persist data.
  A future Hiring context must enforce both before applying a transition.
  """

  @transitions %{
    submitted: [:under_review, :rejected, :withdrawn],
    under_review: [:shortlisted, :rejected, :withdrawn],
    shortlisted: [:interview, :rejected, :withdrawn],
    interview: [:offered, :rejected, :withdrawn],
    offered: [:hired, :rejected, :withdrawn],
    hired: [],
    rejected: [],
    withdrawn: []
  }

  @type t ::
          :submitted
          | :under_review
          | :shortlisted
          | :interview
          | :offered
          | :hired
          | :rejected
          | :withdrawn

  @spec transition(term(), term()) :: {:ok, t()} | {:error, atom()}
  def transition(from, to) do
    cond do
      not Map.has_key?(@transitions, from) -> {:error, :invalid_stage}
      not Map.has_key?(@transitions, to) -> {:error, :invalid_stage}
      to in Map.fetch!(@transitions, from) -> {:ok, to}
      true -> {:error, :invalid_transition}
    end
  end

  @doc "Casts untrusted strings without creating atoms."
  @spec cast(term()) :: {:ok, t()} | {:error, :invalid_stage}
  def cast(value) when is_binary(value) do
    case Enum.find(Map.keys(@transitions), &(Atom.to_string(&1) == value)) do
      nil -> {:error, :invalid_stage}
      stage -> {:ok, stage}
    end
  end

  def cast(_value), do: {:error, :invalid_stage}
end
