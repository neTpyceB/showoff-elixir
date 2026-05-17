defmodule MultiplayerGameBackend.GameRoom do
  @moduledoc false
  use GenServer, restart: :temporary

  alias MultiplayerGameBackend.EventBus

  @tick_ms 200

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def state(pid), do: GenServer.call(pid, :state)

  def player_action(pid, player_id, action),
    do: GenServer.cast(pid, {:player_action, player_id, action})

  def remove_player(pid, player_id), do: GenServer.cast(pid, {:remove_player, player_id})

  @impl true
  def init(opts) do
    room_id = Keyword.fetch!(opts, :room_id)
    players = Keyword.fetch!(opts, :players)

    state = %{
      room_id: room_id,
      players: MapSet.new(players),
      tick: 0,
      last_action: nil
    }

    EventBus.broadcast({:room, room_id}, {:room_started, room_id, players})
    schedule_tick()
    {:ok, state}
  end

  @impl true
  def handle_call(:state, _from, state), do: {:reply, room_payload(state), state}

  @impl true
  def handle_cast({:player_action, player_id, action}, state) do
    if MapSet.member?(state.players, player_id) do
      new_state = %{state | last_action: %{player_id: player_id, action: action}}
      EventBus.broadcast({:room, state.room_id}, {:room_update, room_payload(new_state)})
      {:noreply, new_state}
    else
      {:noreply, state}
    end
  end

  def handle_cast({:remove_player, player_id}, state) do
    players = MapSet.delete(state.players, player_id)
    new_state = %{state | players: players}

    EventBus.broadcast({:room, state.room_id}, {:player_left, state.room_id, player_id})

    if MapSet.size(players) == 0 do
      {:stop, :normal, new_state}
    else
      {:noreply, new_state}
    end
  end

  @impl true
  def handle_info(:tick, state) do
    new_state = %{state | tick: state.tick + 1}
    EventBus.broadcast({:room, state.room_id}, {:room_tick, room_payload(new_state)})
    schedule_tick()
    {:noreply, new_state}
  end

  defp schedule_tick do
    Process.send_after(self(), :tick, @tick_ms)
  end

  defp room_payload(state) do
    %{
      room_id: state.room_id,
      tick: state.tick,
      players: state.players |> MapSet.to_list() |> Enum.sort(),
      last_action: state.last_action
    }
  end
end
