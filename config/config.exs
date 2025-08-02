# This file is responsible for aconfiguring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :stepvo,
  ecto_repos: [Stepvo.Repo],
  generators: [timestamp_type: :utc_datetime]

# Configures the endpoint
config :stepvo, StepvoWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: StepvoWeb.ErrorHTML, json: StepvoWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Stepvo.PubSub,
  live_view: [signing_salt: "6f7Mbch4"]

# Configures the mailer
config :stepvo, Stepvo.Mailer, adapter: Swoosh.Adapters.Local

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.17.11",
  stepvo: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.4.3",
  stepvo: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# --- ADD THIS LINE ---
# This is the configuration the compiler warning asked for.
config :stepvo, ash_domains: [Stepvo.Conversation]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Configure Ash Authentication
config :ash_authentication,
  otp_app: :stepvo

config :ash_authentication_phoenix,
  otp_app: :stepvo

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
