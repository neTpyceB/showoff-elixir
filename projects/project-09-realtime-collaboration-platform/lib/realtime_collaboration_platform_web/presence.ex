defmodule RealtimeCollaborationPlatformWeb.Presence do
  use Phoenix.Presence,
    otp_app: :realtime_collaboration_platform,
    pubsub_server: RealtimeCollaborationPlatform.PubSub
end
