import Config

config :phoenix, :json_library, Jason

config :archethic_playground, ArchethicPlaygroundWeb.Endpoint,
  secret_key_base: "5mFu4p5cPMY5Ii0HvjkLfhYZYtC0JAJofu70bzmi5x3xzFIJNlXFgIY5g8YdDPMf",
  render_errors: [view: ArchethicPlaygroundWeb.ErrorView, accepts: ~w(json)],
  pubsub_server: ArchethicPlayground.PubSub,
  live_view: [
    signing_salt: "3D6jYvx3",
    layout: {ArchethicPlaygroundWeb.LayoutView, "live.html"}
  ]

config :esbuild,
  version: "0.12.18",
  playground: [
    args:
      ~w(js/app.js --bundle --target=es2018 --loader:.ttf=file --outdir=../priv/static/assets),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

config :archethic_playground, ArchethicPlaygroundWeb.DeployComponent,
  mainnet_allowed: System.get_env("MAINNET_ALLOWED", "false") == "true"

config :tailwind,
  version: "3.2.1",
  default: [
    args: ~w(
    --config=tailwind.config.js
    --input=css/app.css
    --output=../priv/static/assets/app.css
  ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Importing Config from the dependency
arch_config = Path.expand("deps/archethic/config/config.exs")

if File.exists?(arch_config) do
  import_config arch_config
end

# override archethic conf for git_hooks
config :git_hooks,
  auto_install: true,
  verbose: true,
  hooks: [
    pre_push: [
      tasks: [
        {:cmd, "mix clean"},
        {:cmd, "mix format --check-formatted"},
        {:cmd, "mix compile --warnings-as-errors"},
        {:cmd, "mix credo"},
        {:cmd, "mix sobelow"},
        {:cmd, "mix knigge.verify"},
        {:cmd, "mix test --trace"},
        {:cmd, "mix dialyzer"}
      ]
    ]
  ]

config :archethic,
       Archethic.Contracts.Interpreter.Library.Common.Chain,
       ArchethicPlayground.MockFunctions

config :archethic,
       Archethic.Contracts.Interpreter.Library.Common.Token,
       ArchethicPlayground.MockFunctions

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
