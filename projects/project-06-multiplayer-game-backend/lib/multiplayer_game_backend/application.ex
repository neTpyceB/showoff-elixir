defmodule MultiplayerGameBackend.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Registry, keys: :unique, name: MultiplayerGameBackend.PlayerRegistry},
      {Registry, keys: :duplicate, name: MultiplayerGameBackend.EventRegistry},
      {DynamicSupervisor, strategy: :one_for_one, name: MultiplayerGameBackend.SessionSupervisor},
      {DynamicSupervisor, strategy: :one_for_one, name: MultiplayerGameBackend.RoomSupervisor},
      {MultiplayerGameBackend.Matchmaker, room_size: 2}
    ]

    opts = [strategy: :one_for_one, name: MultiplayerGameBackend.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
