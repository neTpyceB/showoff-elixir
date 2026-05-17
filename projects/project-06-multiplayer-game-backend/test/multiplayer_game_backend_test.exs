defmodule MultiplayerGameBackendTest do
  use ExUnit.Case, async: false

  alias MultiplayerGameBackend, as: Backend

  setup do
    Backend.reset()
    :ok
  end

  test "creates player sessions and stats" do
    assert :ok = Backend.connect_player("p1")
    assert :ok = Backend.connect_player("p2")

    assert %{connected_players: 2, queued_players: 0, active_rooms: 0} = Backend.stats()
  end

  test "matchmaking creates room and player states synchronize" do
    Backend.connect_player("p1")
    Backend.connect_player("p2")

    Backend.subscribe_player("p1")

    assert :ok = Backend.queue_player("p1")
    assert :ok = Backend.queue_player("p2")

    assert_receive {:realtime_event, {:player, "p1"}, {:matched, room_id, ["p1", "p2"]}}, 1_000

    assert {:ok, %{status: :in_room, room_id: ^room_id}} = Backend.player_state("p1")
    assert {:ok, %{status: :in_room, room_id: ^room_id}} = Backend.player_state("p2")
    assert {:ok, %{room_id: ^room_id}} = Backend.room_state(room_id)
  end

  test "realtime room updates via player action" do
    Backend.connect_player("p1")
    Backend.connect_player("p2")

    Backend.queue_player("p1")
    Backend.queue_player("p2")

    {:ok, %{room_id: room_id}} = Backend.player_state("p1")

    Backend.subscribe_room(room_id)

    assert :ok = Backend.send_action("p1", %{move: "jump"})

    assert_receive {:realtime_event, {:room, ^room_id}, {:room_update, payload}}, 1_000
    assert payload.last_action == %{player_id: "p1", action: %{move: "jump"}}
  end

  test "disconnect recovers from room and queue" do
    Backend.connect_player("p1")
    Backend.connect_player("p2")

    Backend.queue_player("p1")
    Backend.queue_player("p2")

    {:ok, %{room_id: room_id}} = Backend.player_state("p1")

    assert :ok = Backend.disconnect_player("p1")
    assert {:error, :not_found} = Backend.player_state("p1")

    assert {:ok, room_state} = Backend.room_state(room_id)
    assert room_state.players == ["p2"]
  end
end
