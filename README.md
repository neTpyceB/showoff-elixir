# showoff-elixir

Monorepo for 10 learning projects.

## Project Layout Rule

All projects live in separate folders under `projects/`.

Current:

- `projects/project-01-cli-task-utility`
- `projects/project-02-concurrent-web-scraper`
- `projects/project-03-realtime-chat-server`
- `projects/project-04-live-dashboard-system`
- `projects/project-05-fault-tolerant-job-processing-system`
- `projects/project-06-multiplayer-game-backend`
- `projects/project-07-distributed-notification-platform`
- `projects/project-08-event-driven-saas-backend`
- `projects/project-09-realtime-collaboration-platform`

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
docker compose --profile test run --rm project04_test
docker compose --profile test run --rm project05_test
docker compose --profile test run --rm project06_test
docker compose --profile test run --rm project07_test
docker compose --profile test run --rm project08_test
docker compose --profile test run --rm project09_test
```

## CI Rule

- CI runs natively on GitHub runners.
- CI triggers on push only.
- CI runs only for changed project folders.
- Current configured project CI: `project-01-cli-task-utility`, `project-02-concurrent-web-scraper`, `project-03-realtime-chat-server`, `project-04-live-dashboard-system`, `project-05-fault-tolerant-job-processing-system`, `project-06-multiplayer-game-backend`, `project-07-distributed-notification-platform`, `project-08-event-driven-saas-backend`, `project-09-realtime-collaboration-platform`.

## Docs

- [Architecture](docs/ARCHITECTURE.md)
- [API](docs/API.md)
- [Roadmap](docs/ROADMAP.md)
- [File Map](docs/FILE_MAP.md)
- [Working Rules](docs/WORKING_RULES.md)
