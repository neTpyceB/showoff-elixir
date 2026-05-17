defmodule RealtimeCollaborationPlatformWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :realtime_collaboration_platform

  @session_options [
    store: :cookie,
    key: "_realtime_collaboration_platform_key",
    signing_salt: "NniFK5i/",
    same_site: "Lax"
  ]

  socket "/socket", RealtimeCollaborationPlatformWeb.UserSocket,
    websocket: true,
    longpoll: false

  socket "/live", Phoenix.LiveView.Socket,
    websocket: [connect_info: [session: @session_options]],
    longpoll: [connect_info: [session: @session_options]]

  plug Plug.Static,
    at: "/",
    from: :realtime_collaboration_platform,
    gzip: not code_reloading?,
    only: RealtimeCollaborationPlatformWeb.static_paths(),
    raise_on_missing_only: code_reloading?

  if code_reloading? do
    socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
    plug Phoenix.LiveReloader
    plug Phoenix.CodeReloader
  end

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head
  plug Plug.Session, @session_options
  plug RealtimeCollaborationPlatformWeb.Router
end
