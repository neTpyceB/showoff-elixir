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
- `projects/project-03-realtime-chat-server` - Project 3 Phoenix realtime chat server
- `projects/project-03-realtime-chat-server/lib/realtime_chat_server_web/channels/room_channel.ex` - room message handling
- `projects/project-03-realtime-chat-server/lib/realtime_chat_server_web/presence.ex` - live users tracking
- `projects/project-03-realtime-chat-server/lib/realtime_chat_server_web/user_socket.ex` - websocket client socket
- `projects/project-03-realtime-chat-server/test/realtime_chat_server_web/channels/room_channel_test.exs` - channel behavior tests
- `projects/project-04-live-dashboard-system` - Project 4 LiveView realtime dashboard
- `projects/project-04-live-dashboard-system/lib/live_dashboard_system/metrics.ex` - streaming metrics process
- `projects/project-04-live-dashboard-system/lib/live_dashboard_system_web/live/dashboard_live.ex` - LiveView dashboard and graph sync
- `projects/project-04-live-dashboard-system/test/live_dashboard_system/metrics_test.exs` - pub/sub metrics tests
- `projects/project-04-live-dashboard-system/test/live_dashboard_system_web/live/dashboard_live_test.exs` - LiveView sync tests

## CI

- `.github/workflows/ci.yml` - changed-project-only CI
