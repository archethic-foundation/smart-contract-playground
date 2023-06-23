defmodule ArchethicPlayground.MixProject do
  use Mix.Project

  def project do
    [
      app: :archethic_playground,
      version: "0.1.0",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      dialyzer: dialyzer()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {ArchethicPlayground.Application, []}
    ]
  end

  defp dialyzer do
    [
      plt_add_apps: [:archethic]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:phoenix, "~> 1.6"},
      # {:phoenix_live_view, "~> 0.17.9", override: true},
      # {:phoenix_html, "~> 3.1.0", override: true},

      # Added to avoid conflict with archethic-node
      {:phoenix, "~> 1.6"},
      {:phoenix_html, "~> 3.0"},
      {:phoenix_live_view, "~> 0.18"},
      {:phoenix_pubsub, "~> 2.0"},
      {:phoenix_ecto, "~> 4.4"},
      # Added to avoid conflict with archethic-node
      {:ranch, "~> 2.1", override: true},

      # Dev
      {:dialyxir, "~> 1.0", runtime: false},

      # Quality
      {:credo, "~> 1.6", runtime: false},

      # Utils
      {:knigge, "~> 1.4"},
      # Security
m      {:sobelow, "~> 0.11", runtime: false},

      # UI
      {:tailwind, "~> 0.1", runtime: Mix.env() == :dev},
      {:jason, "~> 1.2"},
      {:plug_cowboy, "~> 2.5"},
      {:esbuild, "~> 0.2", runtime: Mix.env() == :dev},
      {:archethic,
        git: "https://github.com/archethic-foundation/archethic-node.git",
       tag: "v1.0.7",
        runtime: false}
    ]
  end

  defp aliases do
    [
      # Intial developer Setup
      "dev.setup": ["deps.get", "cmd npm install --prefix assets"],
      # When Changes are not registered by compiler | any()
      "dev.clean": ["clean", "format", "compile"],
      # run single node
      "dev.run": ["deps.get", "cmd mix dev.clean", "cmd iex -S mix phx.server"],
      # Must be run before git push --no-verify | any(dialyzer issue)
      "dev.checks": [
        "clean",
        "format",
        "compile",
        "credo",
        "sobelow",
        "cmd mix test --trace",
        "dialyzer"
      ],
      # paralele checks
      "dev.pchecks": ["  clean &   format &    compile &   credo &   sobelow & test &   dialyzer"],
      "format.all": ["format", "cmd npm run format --prefix ./assets"],
      "build.assets": ["tailwind default --minify", "esbuild playground --minify", "phx.digest"]
    ]
  end
end
