defmodule Stepvo.Application do
  @moduldoc false

  use Application

  @impl true
  def start(_type, _args) do

    children = [
      StepvoWeb.Telemetry,
      Stepvo.Repo,
      {DNSCluster, query: Application.get_env(:stepvo, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Stepvo.PubSub},
      {Finch, name: Stepvo.Finch},
      StepvoWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: Stepvo.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    StepvoWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
