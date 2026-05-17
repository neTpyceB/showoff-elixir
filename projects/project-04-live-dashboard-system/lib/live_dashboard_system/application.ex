defmodule LiveDashboardSystem.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      LiveDashboardSystemWeb.Telemetry,
      {DNSCluster,
       query: Application.get_env(:live_dashboard_system, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: LiveDashboardSystem.PubSub},
      LiveDashboardSystem.Metrics,
      # Start a worker by calling: LiveDashboardSystem.Worker.start_link(arg)
      # {LiveDashboardSystem.Worker, arg},
      # Start to serve requests, typically the last entry
      LiveDashboardSystemWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: LiveDashboardSystem.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    LiveDashboardSystemWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
