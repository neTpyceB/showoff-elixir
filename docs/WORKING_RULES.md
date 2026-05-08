# Working Rules

## Setup Rules

- Docker-only workflow.
- Separate containers for backend and frontend.
- Hot-reload must stay enabled for local development.
- Keep implementation minimal.

## Validation Rules

After each update:

- run backend tests in Docker
- run frontend checks in Docker
- live-check localhost in browser

## CI Rules

- CI runs natively on GitHub runners (no Docker in CI).
- cancel previous in-progress runs
- run jobs in parallel when possible
- run backend CI only when backend-related files change
- run frontend CI only when frontend-related files change
