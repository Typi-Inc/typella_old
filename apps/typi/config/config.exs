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
  allowed_algos: ["ES512"],
  issuer: "Typi",
  verify_issuer: true,
  ttl: { 36530, :days },
  secret_key: %{
    "alg" => "ES512",
    "crv" => "P-521",
    "d" => "AYGjuosjZcjJxQvsSzeX6FQPOGeIXpAwcQJ81iEukfdGX0ipMzgAJ5piep_muegLE1b8L5V50sydWyoWysTBuJSV",
    "kty" => "EC",
    "use" => "sig",
    "x" => "AL3ihPKSymhrCk4Gde0iOr4ZqfXVLXwRV7nATk_KQDMez_uste1YoYpb4yDudE1PXhIMOmb1rE3lQ0469NGHocea",
    "y" => "AX1Kls2KK6GAtGnD9KoNYEvdcba212zMTsGUj39KdmyyCWvXxJUGA1OUhuuGKXM5RyjFiKBqdflLW0RY1wW72g19"
  },
  serializer: Typi.GuardianSerializer

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
