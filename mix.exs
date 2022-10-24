defmodule ArchethicPlayground.MixProject do
  use Mix.Project

  def project do
    [
      app: :archethic_playground,
      version: "0.1.0",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :archethic],
      mod: {ArchethicPlayground.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:phoenix, "~> 1.6"},
      # {:phoenix_live_view, "~> 0.17.9", override: true},
      # {:phoenix_html, "~> 3.1.0", override: true},

      # Added to avoid conflict with archethic-node
      {:phoenix, ">= 1.5.4"},
      {:phoenix_html, "~> 2.14"},
      {:phoenix_live_view, "~> 0.15.0"},
      {:phoenix_pubsub, "~> 2.0"},
      # Added to avoid conflict with archethic-node
      {:ranch, "~> 2.1", override: true},

      # Dev
      {:dialyxir, "~> 1.0", runtime: false},

      # Quality
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},

      # Utils
      {:knigge, "~> 1.4"},
      # Security
      {:sobelow, ">= 0.11.1", only: [:test, :dev], runtime: false},
      {:jason, "~> 1.2"},
      {:plug_cowboy, "~> 2.5"},
      {:esbuild, "~> 0.2", runtime: Mix.env() == :dev},
      {:dart_sass, "~> 0.4", runtime: Mix.env() == :dev},
      {:archethic,
       git: "https://github.com/archethic-foundation/archethic-node.git", tag: "v0.25.0"}
    ]
  end

  defp aliases do
    [
      setup: ["deps.get"],
      "assets.deploy": [
        "esbuild default --minify",
        "sass default --no-source-map --style=compressed",
        "phx.digest"
      ]
    ]
  end
end
