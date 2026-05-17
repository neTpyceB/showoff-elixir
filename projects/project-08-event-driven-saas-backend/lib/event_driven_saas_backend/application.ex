defmodule EventDrivenSaasBackend.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Registry, keys: :duplicate, name: EventDrivenSaasBackend.EventRegistry},
      {EventDrivenSaasBackend.Platform, []}
    ]

    opts = [strategy: :one_for_one, name: EventDrivenSaasBackend.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
