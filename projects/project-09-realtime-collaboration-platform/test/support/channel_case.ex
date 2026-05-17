defmodule RealtimeCollaborationPlatformWeb.ChannelCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      @endpoint RealtimeCollaborationPlatformWeb.Endpoint

      use RealtimeCollaborationPlatformWeb, :verified_routes

      import Phoenix.ChannelTest
      import RealtimeCollaborationPlatformWeb.ChannelCase
    end
  end
end
