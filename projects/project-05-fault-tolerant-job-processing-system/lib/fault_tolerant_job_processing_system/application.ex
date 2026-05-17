defmodule FaultTolerantJobProcessingSystem.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {DynamicSupervisor,
       strategy: :one_for_one, name: FaultTolerantJobProcessingSystem.WorkerSupervisor},
      {FaultTolerantJobProcessingSystem.Server, max_workers: 3, default_max_retries: 2}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: FaultTolerantJobProcessingSystem.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
