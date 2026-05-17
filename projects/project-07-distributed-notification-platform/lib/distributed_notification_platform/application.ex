defmodule DistributedNotificationPlatform.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      %{
        id: DistributedNotificationPlatform.PubSub,
        start: {:pg, :start_link, [DistributedNotificationPlatform.PubSub]}
      },
      {DynamicSupervisor,
       strategy: :one_for_one, name: DistributedNotificationPlatform.ReceiverSupervisor},
      {DynamicSupervisor,
       strategy: :one_for_one, name: DistributedNotificationPlatform.DeliverySupervisor},
      {DistributedNotificationPlatform.Router, retry_delay_ms: 50, max_retries: 2}
    ]

    opts = [strategy: :one_for_one, name: DistributedNotificationPlatform.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
