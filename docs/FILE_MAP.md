# File Map

## Root

- `AGENTS.md` - agent operating instruction entrypoint
- `README.md` - project overview and documentation links
- `docker-compose.yml` - dev/test container orchestration

## docs

- `docs/ARCHITECTURE.md` - target repository architecture
- `docs/API.md` - API status and contract placeholder
- `docs/ROADMAP.md` - implementation phases
- `docs/FILE_MAP.md` - repository file index
- `docs/WORKING_RULES.md` - setup, validation, and CI operating rules

## backend

- `backend/` - Elixir backend workspace
- `backend/lib/task_cli.ex` - todo domain logic
- `backend/lib/task_cli/cli.ex` - terminal command parsing and execution
- `backend/lib/task_cli/store.ex` - file storage for todos
- `backend/test/task_cli_test.exs` - todo unit tests
- `backend/test/task_cli_cli_test.exs` - CLI command flow tests

## frontend

- `frontend/` - frontend workspace

## CI

- `.github/workflows/ci.yml` - path-aware parallel CI with cancel-in-progress
