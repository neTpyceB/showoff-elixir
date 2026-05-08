# showoff-elixir

Local: Docker-only. CI: native GitHub runners.

## Start Dev (Hot Reload)

```bash
docker compose --profile dev up
```

- frontend dev server: [http://localhost:5173](http://localhost:5173)
- backend watch mode: test watcher in container

## Run Checks

```bash
docker compose --profile test run --rm backend_test
docker compose --profile test run --rm frontend_test
```

## CI

- No Docker in CI.
- Backend CI runs directly with Elixir/OTP on runner.
- Frontend CI runs directly with Node on runner.

## Docs

- [Architecture](docs/ARCHITECTURE.md)
- [API](docs/API.md)
- [Roadmap](docs/ROADMAP.md)
- [File Map](docs/FILE_MAP.md)
- [Working Rules](docs/WORKING_RULES.md)
