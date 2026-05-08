# Task CLI Utility (Elixir)

Terminal todo utility with:

- todo management (`add`, `list`, `done`, `delete`)
- file storage
- command parsing

## Run

```bash
mix run -e 'TaskCli.CLI.main(["help"])'
mix run -e 'TaskCli.CLI.main(["add", "learn", "elixir"])'
mix run -e 'TaskCli.CLI.main(["list"])'
```

## Build executable

```bash
mix escript.build
./task_cli help
./task_cli add "write tests"
./task_cli list
```

## Storage

Default file:

- `.task_cli_todos` in current working directory

Optional env override:

- `TASK_CLI_STORE=/path/to/file`
