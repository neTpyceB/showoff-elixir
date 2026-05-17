defmodule MultiplayerGameBackend.Matchmaker do
  @moduledoc false
  use GenServer

  alias MultiplayerGameBackend.{EventBus, GameRoom, PlayerSession}

  @default_room_size 2

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def connect_player(player_id), do: GenServer.call(__MODULE__, {:connect_player, player_id})

  def disconnect_player(player_id),
    do: GenServer.call(__MODULE__, {:disconnect_player, player_id})

  def queue_player(player_id), do: GenServer.call(__MODULE__, {:queue_player, player_id})

  def send_action(player_id, action),
    do: GenServer.call(__MODULE__, {:send_action, player_id, action})

  def player_state(player_id), do: GenServer.call(__MODULE__, {:player_state, player_id})
  def room_state(room_id), do: GenServer.call(__MODULE__, {:room_state, room_id})
  def stats, do: GenServer.call(__MODULE__, :stats)
  def reset, do: GenServer.call(__MODULE__, :reset)

  @impl true
  def init(opts) do
    {:ok,
     %{
       room_size: Keyword.get(opts, :room_size, @default_room_size),
       next_room_id: 1,
       queued_players: MapSet.new(),
       queue: :queue.new(),
       player_rooms: %{},
       room_pids: %{}
     }}
  end

  @impl true
  def handle_call({:connect_player, player_id}, _from, state) do
    if PlayerSession.whereis(player_id) do
      {:reply, {:error, :already_connected}, state}
    else
      case DynamicSupervisor.start_child(
             MultiplayerGameBackend.SessionSupervisor,
             {PlayerSession, player_id}
           ) do
        {:ok, _pid} ->
          EventBus.broadcast(:lobby, {:player_connected, player_id})
          {:reply, :ok, state}

        error ->
          {:reply, error, state}
      end
    end
  end

  def handle_call({:disconnect_player, player_id}, _from, state) do
    state =
      state
      |> remove_from_queue(player_id)
      |> remove_from_room(player_id)

    stop_player_session(player_id)

    EventBus.broadcast(:lobby, {:player_disconnected, player_id})
    {:reply, :ok, state}
  end

  def handle_call({:queue_player, player_id}, _from, state) do
    cond do
      MapSet.member?(state.queued_players, player_id) ->
        {:reply, {:error, :not_connected_or_already_queued}, state}

      true ->
        case safe_player_state(player_id) do
          {:ok, %{status: :online}} ->
            PlayerSession.mark_matching(player_id)

            state =
              state
              |> enqueue(player_id)
              |> match_rooms()

            EventBus.broadcast(:lobby, {:player_queued, player_id})
            {:reply, :ok, state}

          {:ok, %{status: _}} ->
            {:reply, {:error, :not_available}, state}

          {:error, :not_found} ->
            {:reply, {:error, :not_connected_or_already_queued}, state}
        end
    end
  end

  def handle_call({:send_action, player_id, action}, _from, state) do
    case Map.fetch(state.player_rooms, player_id) do
      {:ok, room_id} ->
        case Map.fetch(state.room_pids, room_id) do
          {:ok, room_pid} ->
            GameRoom.player_action(room_pid, player_id, action)
            {:reply, :ok, state}

          :error ->
            {:reply, {:error, :room_not_found}, state}
        end

      :error ->
        {:reply, {:error, :not_in_room}, state}
    end
  end

  def handle_call({:player_state, player_id}, _from, state) do
    {:reply, safe_player_state(player_id), state}
  end

  def handle_call({:room_state, room_id}, _from, state) do
    reply =
      case Map.fetch(state.room_pids, room_id) do
        {:ok, pid} -> {:ok, GameRoom.state(pid)}
        :error -> {:error, :not_found}
      end

    {:reply, reply, state}
  end

  def handle_call(:stats, _from, state) do
    {:reply,
     %{
       connected_players: connected_player_count(),
       queued_players: MapSet.size(state.queued_players),
       active_rooms: map_size(state.room_pids)
     }, state}
  end

  def handle_call(:reset, _from, state) do
    Enum.each(state.room_pids, fn {_room_id, room_pid} ->
      DynamicSupervisor.terminate_child(MultiplayerGameBackend.RoomSupervisor, room_pid)
    end)

    Registry.select(MultiplayerGameBackend.PlayerRegistry, [{{:"$1", :_, :_}, [], [:"$1"]}])
    |> Enum.each(fn player_id ->
      stop_player_session(player_id)
    end)

    new_state = %{
      state
      | queued_players: MapSet.new(),
        queue: :queue.new(),
        player_rooms: %{},
        room_pids: %{}
    }

    {:reply, :ok, new_state}
  end

  defp connected_player_count do
    Registry.count(MultiplayerGameBackend.PlayerRegistry)
  end

  defp enqueue(state, player_id) do
    %{
      state
      | queued_players: MapSet.put(state.queued_players, player_id),
        queue: :queue.in(player_id, state.queue)
    }
  end

  defp match_rooms(state) do
    if :queue.len(state.queue) >= state.room_size do
      {players, queue} = take_players(state.queue, state.room_size, [])
      room_id = "room-#{state.next_room_id}"

      case DynamicSupervisor.start_child(
             MultiplayerGameBackend.RoomSupervisor,
             {GameRoom, [room_id: room_id, players: players]}
           ) do
        {:ok, room_pid} ->
          Enum.each(players, fn player_id ->
            PlayerSession.assign_room(player_id, room_id)
            EventBus.broadcast({:player, player_id}, {:matched, room_id, players})
          end)

          EventBus.broadcast(:lobby, {:room_created, room_id, players})

          state =
            state
            |> Map.put(:queue, queue)
            |> Map.update!(:next_room_id, &(&1 + 1))
            |> Map.update!(:queued_players, fn set ->
              Enum.reduce(players, set, &MapSet.delete(&2, &1))
            end)
            |> Map.update!(:player_rooms, fn map ->
              Enum.reduce(players, map, &Map.put(&2, &1, room_id))
            end)
            |> Map.put(:room_pids, Map.put(state.room_pids, room_id, room_pid))

          match_rooms(state)

        {:error, _reason} ->
          state
      end
    else
      state
    end
  end

  defp take_players(queue, 0, acc), do: {Enum.reverse(acc), queue}

  defp take_players(queue, count, acc) do
    case :queue.out(queue) do
      {{:value, player_id}, rest} -> take_players(rest, count - 1, [player_id | acc])
      {:empty, rest} -> {Enum.reverse(acc), rest}
    end
  end

  defp remove_from_queue(state, player_id) do
    if MapSet.member?(state.queued_players, player_id) do
      queue =
        state.queue
        |> :queue.to_list()
        |> Enum.reject(&(&1 == player_id))
        |> :queue.from_list()

      clear_player_room(player_id)

      %{state | queue: queue, queued_players: MapSet.delete(state.queued_players, player_id)}
    else
      state
    end
  end

  defp remove_from_room(state, player_id) do
    case Map.fetch(state.player_rooms, player_id) do
      {:ok, room_id} ->
        case Map.fetch(state.room_pids, room_id) do
          {:ok, room_pid} -> GameRoom.remove_player(room_pid, player_id)
          :error -> :ok
        end

        clear_player_room(player_id)

        %{state | player_rooms: Map.delete(state.player_rooms, player_id)}

      :error ->
        state
    end
  end

  defp safe_player_state(player_id) do
    case PlayerSession.whereis(player_id) do
      nil ->
        {:error, :not_found}

      pid ->
        try do
          {:ok, GenServer.call(pid, :state)}
        catch
          :exit, _ -> {:error, :not_found}
        end
    end
  end

  defp stop_player_session(player_id) do
    case PlayerSession.whereis(player_id) do
      nil ->
        :ok

      pid ->
        try do
          GenServer.stop(pid, :normal)
        catch
          :exit, _ -> :ok
        end
    end
  end

  defp clear_player_room(player_id) do
    case PlayerSession.whereis(player_id) do
      nil -> :ok
      pid -> GenServer.cast(pid, :clear_room)
    end
  end
end
