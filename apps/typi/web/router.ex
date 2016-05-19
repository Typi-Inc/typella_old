defmodule Typi.Router do
  use Typi.Web, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", Typi do
    pipe_through :api
  end
end
