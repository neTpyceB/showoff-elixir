# Multiplayer Game Backend

Features:

- player sessions
- matchmaking
- realtime updates
- game rooms

Architecture:

- OTP supervisor tree
- Dynamic supervisors for sessions and rooms
- event pub/sub via `Registry`

## Run tests

```bash
mix test
```

## Example

```elixir
MultiplayerGameBackend.connect_player("p1")
MultiplayerGameBackend.connect_player("p2")
MultiplayerGameBackend.queue_player("p1")
MultiplayerGameBackend.queue_player("p2")
MultiplayerGameBackend.send_action("p1", %{move: "jump"})
```
