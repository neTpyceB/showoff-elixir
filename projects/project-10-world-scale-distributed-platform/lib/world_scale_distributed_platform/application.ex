defmodule WorldScaleDistributedPlatform.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      %{
        id: WorldScaleDistributedPlatform.PubSubScope,
        start: {:pg, :start_link, [WorldScaleDistributedPlatform.PubSubScope]}
      },
      {Registry, keys: :unique, name: WorldScaleDistributedPlatform.GatewayRegistry},
      {DynamicSupervisor,
       strategy: :one_for_one, name: WorldScaleDistributedPlatform.GatewaySupervisor},
      {WorldScaleDistributedPlatform.Platform, initial_gateways: 4}
    ]

    opts = [strategy: :one_for_one, name: WorldScaleDistributedPlatform.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
