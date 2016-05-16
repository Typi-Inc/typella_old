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
  secret_key_base: "SUNDh/UKDDMrR1mZuD6rsTvFwuA28yA38N/0mf+N7yYvExqsCeSR5cszCynbWb93",
  render_errors: [view: Typi.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Typi.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
