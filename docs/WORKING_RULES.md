# Working Rules

## Project Structure Rules

- Every project must be in its own folder inside `projects/`.
- Folder naming format: `project-XX-short-name`.
- Each project folder is self-contained.
- No shared runtime code across projects unless explicitly required.

## Local Setup Rules

- Local development is Docker-only.
- Do not install project runtimes on laptop.
- Keep implementation minimal.

## Validation Rules

After each update for a project:

- run that project's tests in Docker
- run that project's required local check(s)

## CI Rules

- CI runs natively on GitHub runners (no Docker in CI).
- Cancel previous in-progress runs.
- Run project jobs in parallel when possible.
- Run CI only for changed project folder(s).
- Do not run unrelated project jobs.
- For every new project folder, add a matching path filter and CI job.
