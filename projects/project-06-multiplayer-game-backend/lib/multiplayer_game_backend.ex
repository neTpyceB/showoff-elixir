defmodule MultiplayerGameBackend do
  @moduledoc false

  alias MultiplayerGameBackend.{EventBus, Matchmaker}

  def connect_player(player_id), do: Matchmaker.connect_player(player_id)
  def disconnect_player(player_id), do: Matchmaker.disconnect_player(player_id)
  def queue_player(player_id), do: Matchmaker.queue_player(player_id)
  def send_action(player_id, action), do: Matchmaker.send_action(player_id, action)
  def player_state(player_id), do: Matchmaker.player_state(player_id)
  def room_state(room_id), do: Matchmaker.room_state(room_id)
  def stats, do: Matchmaker.stats()
  def reset, do: Matchmaker.reset()

  def subscribe_lobby, do: EventBus.subscribe(:lobby)
  def subscribe_player(player_id), do: EventBus.subscribe({:player, player_id})
  def subscribe_room(room_id), do: EventBus.subscribe({:room, room_id})
end
