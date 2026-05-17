# Event-driven SaaS Backend

Features:

- organizations
- RBAC
- event streams
- audit logs

Architecture:

- `Platform` GenServer stores org/member/event/audit state
- `Registry` duplicate keys for per-organization event subscriptions
- RBAC permissions enforced for manage/publish/read operations

## Run tests

```bash
mix test
```

## Example

```elixir
EventDrivenSaasBackend.create_organization("org-1", "owner-1")
EventDrivenSaasBackend.add_member("org-1", "owner-1", "user-1", :member)
EventDrivenSaasBackend.subscribe_events("org-1")
EventDrivenSaasBackend.publish_event("org-1", "user-1", "invoice.created", %{id: 10})
EventDrivenSaasBackend.list_audit_logs("org-1", "owner-1")
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/event_driven_saas_backend>.
