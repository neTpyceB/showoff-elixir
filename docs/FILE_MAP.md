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
- `projects/project-05-fault-tolerant-job-processing-system` - Project 5 OTP job system
- `projects/project-05-fault-tolerant-job-processing-system/lib/fault_tolerant_job_processing_system/server.ex` - queue/retry/recovery manager
- `projects/project-05-fault-tolerant-job-processing-system/lib/fault_tolerant_job_processing_system/worker.ex` - pool worker execution
- `projects/project-05-fault-tolerant-job-processing-system/test/fault_tolerant_job_processing_system_test.exs` - pool/retry/failure tests
- `projects/project-06-multiplayer-game-backend` - Project 6 realtime multiplayer backend
- `projects/project-06-multiplayer-game-backend/lib/multiplayer_game_backend/matchmaker.ex` - player sessions + matchmaking
- `projects/project-06-multiplayer-game-backend/lib/multiplayer_game_backend/game_room.ex` - game room realtime updates
- `projects/project-06-multiplayer-game-backend/lib/multiplayer_game_backend/player_session.ex` - player session process
- `projects/project-06-multiplayer-game-backend/test/multiplayer_game_backend_test.exs` - session/matchmaking/room tests
- `projects/project-07-distributed-notification-platform` - Project 7 distributed notification platform
- `projects/project-07-distributed-notification-platform/lib/distributed_notification_platform/router.ex` - distributed pub/sub fanout and retry accounting
- `projects/project-07-distributed-notification-platform/lib/distributed_notification_platform/receiver.ex` - notification endpoint subscriber process
- `projects/project-07-distributed-notification-platform/lib/distributed_notification_platform/delivery_worker.ex` - retrying delivery worker process
- `projects/project-07-distributed-notification-platform/test/distributed_notification_platform_test.exs` - pub/sub delivery and retry tests

## CI

- `.github/workflows/ci.yml` - changed-project-only CI
