defmodule MultiplayerGameBackend.PlayerSession do
  @moduledoc false
  use GenServer, restart: :temporary

  @registry MultiplayerGameBackend.PlayerRegistry

  def start_link(player_id) do
    GenServer.start_link(__MODULE__, player_id, name: via(player_id))
  end

  def whereis(player_id) do
    case Registry.lookup(@registry, player_id) do
      [{pid, _}] -> pid
      [] -> nil
    end
  end

  def state(player_id), do: GenServer.call(via(player_id), :state)
  def mark_matching(player_id), do: GenServer.cast(via(player_id), :mark_matching)
  def assign_room(player_id, room_id), do: GenServer.cast(via(player_id), {:assign_room, room_id})
  def clear_room(player_id), do: GenServer.cast(via(player_id), :clear_room)
  def stop(player_id), do: GenServer.stop(via(player_id), :normal)

  @impl true
  def init(player_id) do
    {:ok, %{player_id: player_id, status: :online, room_id: nil}}
  end

  @impl true
  def handle_call(:state, _from, state), do: {:reply, state, state}

  @impl true
  def handle_cast(:mark_matching, state),
    do: {:noreply, %{state | status: :matching, room_id: nil}}

  def handle_cast({:assign_room, room_id}, state),
    do: {:noreply, %{state | status: :in_room, room_id: room_id}}

  def handle_cast(:clear_room, state), do: {:noreply, %{state | status: :online, room_id: nil}}

  defp via(player_id), do: {:via, Registry, {@registry, player_id}}
end
