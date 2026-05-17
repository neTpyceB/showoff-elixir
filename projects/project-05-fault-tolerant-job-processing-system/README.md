# Fault-tolerant Job Processing System (OTP)

Features:

- worker pool
- retries
- failure recovery
- supervisor tree

## Run tests

```bash
mix test
```

## Example

```elixir
FaultTolerantJobProcessingSystem.submit(%{mode: :ok, value: "hello"})
FaultTolerantJobProcessingSystem.submit(%{mode: :flaky_crash, fail_attempts: 1, value: "ok"}, max_retries: 2)
FaultTolerantJobProcessingSystem.stats()
FaultTolerantJobProcessingSystem.results()
```
