# Architecture

## Scope

Monorepo containing 10 independent learning projects.

## Structure

- `projects/` - all project folders
- `projects/project-XX-short-name/` - one project per folder
- `docs/` - shared documentation

## Current Projects

- `project-01-cli-task-utility` (Elixir terminal app)
- `project-02-concurrent-web-scraper` (Elixir concurrent terminal app)
- `project-03-realtime-chat-server` (Phoenix websocket app)
- `project-04-live-dashboard-system` (Phoenix LiveView realtime dashboard)
- `project-05-fault-tolerant-job-processing-system` (OTP worker pool + retries)
- `project-06-multiplayer-game-backend` (OTP matchmaking + realtime rooms)
- `project-07-distributed-notification-platform` (distributed pub/sub + notification retries)
- `project-08-event-driven-saas-backend` (organizations + RBAC + event streams + audit logs)
- `project-09-realtime-collaboration-platform` (websocket collaboration + presence + distributed doc state)
