defmodule RealtimeChatServerWeb.Presence do
  use Phoenix.Presence,
    otp_app: :realtime_chat_server,
    pubsub_server: RealtimeChatServer.PubSub
end
