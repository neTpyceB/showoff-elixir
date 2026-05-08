# showoff-elixir

Monorepo for 10 learning projects.

## Project Layout Rule

All projects must live in their own folder under `projects/`.

Example:

- `projects/project-01-cli-task-utility`
- `projects/project-02-...`
- ... up to project 10

## Local Run (Docker-only)

```bash
docker compose up -d
```

## Local Tests (Docker-only)

```bash
docker compose --profile test run --rm project01_test
```

## CI Rule

- CI runs natively on GitHub runners.
- CI runs only for changed project folders.
- Current configured project CI: `project-01-cli-task-utility`.

## Docs

- [Architecture](docs/ARCHITECTURE.md)
- [API](docs/API.md)
- [Roadmap](docs/ROADMAP.md)
- [File Map](docs/FILE_MAP.md)
- [Working Rules](docs/WORKING_RULES.md)
