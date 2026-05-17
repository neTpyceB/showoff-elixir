defmodule RealtimeCollaborationPlatform.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      RealtimeCollaborationPlatformWeb.Telemetry,
      {DNSCluster,
       query: Application.get_env(:realtime_collaboration_platform, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: RealtimeCollaborationPlatform.PubSub},
      RealtimeCollaborationPlatformWeb.Presence,
      {DynamicSupervisor,
       strategy: :one_for_one, name: RealtimeCollaborationPlatform.DocumentSupervisor},
      RealtimeCollaborationPlatformWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: RealtimeCollaborationPlatform.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    RealtimeCollaborationPlatformWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
