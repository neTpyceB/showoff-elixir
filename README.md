# showoff-elixir

Monorepo for 10 learning projects.

## Project Layout Rule

All projects live in separate folders under `projects/`.

Current:

- `projects/project-01-cli-task-utility`
- `projects/project-02-concurrent-web-scraper`
- `projects/project-03-realtime-chat-server`

When creating a new project, existing project folders are not modified unless explicitly requested.

## Local Run (Docker-only)

```bash
docker compose up -d
```

## Local Tests (Docker-only)

```bash
docker compose --profile test run --rm project01_test
docker compose --profile test run --rm project02_test
docker compose --profile test run --rm project03_test
```

## CI Rule

- CI runs natively on GitHub runners.
- CI triggers on push only.
- CI runs only for changed project folders.
- Current configured project CI: `project-01-cli-task-utility`, `project-02-concurrent-web-scraper`, `project-03-realtime-chat-server`.

## Docs

- [Architecture](docs/ARCHITECTURE.md)
- [API](docs/API.md)
- [Roadmap](docs/ROADMAP.md)
- [File Map](docs/FILE_MAP.md)
- [Working Rules](docs/WORKING_RULES.md)
