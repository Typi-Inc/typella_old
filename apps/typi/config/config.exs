# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :typi,
  ecto_repos: [Typi.Repo]

# Configures the endpoint
config :typi, Typi.Endpoint,
  url: [host: "localhost"],
  root: Path.dirname(__DIR__),
  secret_key_base: "f8XY4OksMiL1C7JmdnaduKsBXhMXDltP7RUSjDi+Dwob+3j6lJDFtPKZteuLakW8",
  render_errors: [view: Typi.ErrorView, accepts: ~w(json)],
  pubsub: [name: Typi.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :ex_twilio, account_sid: System.get_env("TWILIO_ACCOUNT_SID"),
  auth_token: System.get_env("TWILIO_AUTH_TOKEN"),
  phone_number: System.get_env("TWILIO_PHONE_NUMBER")

config :guardian, Guardian,
  allowed_algos: ["Ed448"],
  issuer: "Typi",
  verify_issuer: true,
  ttl: { 30, :days },
  secret_key: %{
    "alg" => "Ed448",
    "crv" => "Ed448",
    "d" => "phRI3ziBAeU-w0DagrNkKBmldNePpOblE4UECo8rzF70cBVxtbcZaq5xmyZDG27CbZ6upFS7U519",
    "kty" => "OKP", "use" => "sig",
    "x" => "1UaCq7TgZKrsdtOXGG6CtwTiTIR2MRYbt45H-ZEX4P8VuoUSS9ShbuQP0o57V-I2Gspz4V71D4qA"
  },
  serializer: Typi.GuardianSerializer

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
