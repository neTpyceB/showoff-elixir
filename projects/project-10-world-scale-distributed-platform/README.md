# World-scale Distributed Platform

Goal:

- clustered Elixir nodes
- distributed pub/sub
- realtime messaging
- fault-tolerant supervisors
- observability systems

Features:

- millions of concurrent connections simulation
- distributed event system
- resilience testing
- self-healing recovery

Architecture:

- `Platform` GenServer coordinates cluster/runtime state
- `Gateway` workers simulate massive connection shards
- `DynamicSupervisor` self-heals crashed gateways
- `:pg` scope powers distributed pub/sub and event fanout

## Run tests

```bash
mix test
```

## Example

```elixir
WorldScaleDistributedPlatform.simulate_connections(1_000_000, 16)
WorldScaleDistributedPlatform.subscribe_channel("global-chat")
WorldScaleDistributedPlatform.publish_message("global-chat", %{text: "hi"})
WorldScaleDistributedPlatform.run_resilience_test(1)
WorldScaleDistributedPlatform.stats()
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/world_scale_distributed_platform>.
