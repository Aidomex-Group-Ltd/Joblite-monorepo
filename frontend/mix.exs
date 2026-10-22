defmodule Joblite.Web.MixProject do
  use Mix.Project

  def project do
    [
      app: :joblite_web,
      version: "0.1.0",
      elixir: "~> 1.20.0",
      elixirc_paths: if(Mix.env() == :test, do: ["lib", "test/support"], else: ["lib"]),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      releases: [joblite: [applications: [joblite_core: :permanent, joblite_web: :permanent]]]
    ]
  end

  def application do
    [extra_applications: [:logger, :runtime_tools], mod: {JobliteWeb.Application, []}]
  end

  def cli do
    [preferred_envs: [check: :test]]
  end

  defp deps do
    [
      {:joblite_core, path: "../backend", env: Mix.env()},
      {:phoenix, "~> 1.8.0"},
      {:phoenix_live_view, "~> 1.2.0"},
      {:phoenix_html, "~> 4.3"},
      {:bandit, "~> 1.0"},
      {:jason, "~> 1.4"},
      {:swoosh, "~> 1.19"},
      {:gen_smtp, "~> 1.2"},
      {:esbuild, "~> 0.10", runtime: Mix.env() == :dev},
      {:lazy_html, ">= 0.1.0", only: :test},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:sobelow, "~> 0.14", only: [:dev, :test], runtime: false}
    ]
  end

  defp aliases do
    [
      "assets.setup": ["esbuild.install --if-missing"],
      "assets.build": ["esbuild default"],
      "assets.deploy": ["esbuild default --minify", "phx.digest"],
      check: ["format --check-formatted", "compile --warnings-as-errors", "credo", "test"]
    ]
  end
end
