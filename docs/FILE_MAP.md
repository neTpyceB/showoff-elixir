# File Map

## Root

- `AGENTS.md` - agent operating instruction entrypoint
- `README.md` - repo overview and rules summary
- `docker-compose.yml` - local Docker services

## docs

- `docs/ARCHITECTURE.md` - target repository architecture
- `docs/API.md` - API status
- `docs/ROADMAP.md` - implementation phases
- `docs/FILE_MAP.md` - repository file index
- `docs/WORKING_RULES.md` - persistent operating rules

## projects

- `projects/project-01-cli-task-utility` - Project 1 terminal todo CLI
- `projects/project-01-cli-task-utility/lib/task_cli.ex` - todo logic
- `projects/project-01-cli-task-utility/lib/task_cli/cli.ex` - CLI parsing/commands
- `projects/project-01-cli-task-utility/lib/task_cli/store.ex` - file persistence
- `projects/project-01-cli-task-utility/test/task_cli_test.exs` - domain tests
- `projects/project-01-cli-task-utility/test/task_cli_cli_test.exs` - CLI flow tests
- `projects/project-02-concurrent-web-scraper` - Project 2 concurrent scraper CLI
- `projects/project-02-concurrent-web-scraper/lib/concurrent_web_scraper.ex` - concurrent fetch + aggregation
- `projects/project-02-concurrent-web-scraper/lib/concurrent_web_scraper/cli.ex` - CLI parsing and output
- `projects/project-02-concurrent-web-scraper/test/concurrent_web_scraper_test.exs` - concurrency + timeout tests
- `projects/project-02-concurrent-web-scraper/test/concurrent_web_scraper_cli_test.exs` - CLI tests

## CI

- `.github/workflows/ci.yml` - changed-project-only CI
