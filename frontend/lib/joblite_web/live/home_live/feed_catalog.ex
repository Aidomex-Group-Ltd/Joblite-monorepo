defmodule JobliteWeb.HomeLive.FeedCatalog do
  @moduledoc "Three fictional posts for exercising the interface without a database."
  @base "/assets/joblite-feed/"

  @spec posts() :: [map()]
  def posts do
    [
      %{
        id: "nova",
        author: "Nova Studio",
        handle: "@novastudio",
        initial: "N",
        tone: "nova",
        time: "Sample",
        mine: false,
        following: false,
        body:
          "Good work starts with good people. We’re looking for a Product Designer. Here’s a little of what we’re building. 👋",
        role: %{title: "Product Designer", arrangement: "Remote · Full time"},
        media: [
          %{
            id: "nova-video",
            kind: "video",
            local: false,
            source: @base <> "studio-intro.webm",
            thumbnail: @base <> "nova-poster.jpg",
            alt: "Nova Studio: Good work. Great people.",
            duration: "0:03"
          }
        ]
      },
      %{
        id: "amina",
        author: "Amina K.",
        handle: "@amina.design",
        initial: "A",
        tone: "amina",
        time: "Sample",
        mine: false,
        following: true,
        role: nil,
        body:
          "A little look at an onboarding flow. Less friction, more flow.\nOpen to product design opportunities.",
        media: [
          %{
            id: "finch",
            kind: "image",
            local: false,
            source: @base <> "finch.jpg",
            thumbnail: @base <> "finch-thumb.jpg",
            alt: "Finch product design: a calmer way to work.",
            duration: nil
          },
          %{
            id: "onboarding",
            kind: "image",
            local: false,
            source: @base <> "onboarding.jpg",
            thumbnail: @base <> "onboarding-thumb.jpg",
            alt: "A mobile onboarding design study.",
            duration: nil
          }
        ]
      },
      %{
        id: "jordan",
        author: "Jordan M.",
        handle: "@jordanbuilds",
        initial: "J",
        tone: "you",
        time: "Sample",
        mine: false,
        following: true,
        role: nil,
        media: [],
        body:
          "A hiring process I’d love to see more often:\n\nShow the work. Explain the criteria. Keep people in the loop.\n\nA little clarity goes a long way."
      }
    ]
  end
end
