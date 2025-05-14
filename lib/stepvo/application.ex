defmodule Stepvo.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      StepvoWeb.Telemetry,
      Stepvo.Repo,
      {DNSCluster, query: Application.get_env(:stepvo, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Stepvo.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Stepvo.Finch},
      # Start a worker by calling: Stepvo.Worker.start_link(arg)
      # {Stepvo.Worker, arg},
      # Start to serve requests, typically the last entry
      StepvoWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Stepvo.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    StepvoWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
