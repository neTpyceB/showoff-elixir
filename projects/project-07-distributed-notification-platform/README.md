# Distributed Notification Platform

Features:

- distributed nodes support (`Node.connect/1`, `Node.list/0`)
- pub/sub messaging via `:pg` process groups
- notification delivery to subscribers
- retry system for transient delivery failures

Architecture:

- `Router` coordinates topic fanout and retry accounting
- `DeliveryWorker` performs isolated delivery attempts
- `Receiver` acts as notification endpoint and subscriber process
- supervisors isolate receivers and delivery workers

## Run tests

```bash
mix test
```

## Example

```elixir
DistributedNotificationPlatform.start_receiver("r1")
DistributedNotificationPlatform.subscribe("r1", "orders")
DistributedNotificationPlatform.publish("orders", %{event: "created", id: 10})
DistributedNotificationPlatform.notifications("r1")
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/distributed_notification_platform>.
