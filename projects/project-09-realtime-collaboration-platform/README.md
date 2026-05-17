# Realtime Collaboration Platform

Features:

- live collaborative editing
- websocket synchronization
- presence tracking
- distributed state

Architecture:

- `CollabChannel` handles realtime document collaboration traffic
- `Presence` tracks active users per document channel
- `DocumentState` uses global process naming for shared cross-node document state

To start your Phoenix server:

  * Run `mix setup` to install and setup dependencies
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`
