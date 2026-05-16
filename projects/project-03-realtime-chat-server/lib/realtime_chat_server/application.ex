defmodule RealtimeChatServer.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      RealtimeChatServerWeb.Telemetry,
      {DNSCluster,
       query: Application.get_env(:realtime_chat_server, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: RealtimeChatServer.PubSub},
      RealtimeChatServerWeb.Presence,
      # Start a worker by calling: RealtimeChatServer.Worker.start_link(arg)
      # {RealtimeChatServer.Worker, arg},
      # Start to serve requests, typically the last entry
      RealtimeChatServerWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: RealtimeChatServer.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    RealtimeChatServerWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
