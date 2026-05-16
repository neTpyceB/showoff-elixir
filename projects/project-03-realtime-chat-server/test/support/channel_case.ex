defmodule RealtimeChatServerWeb.ChannelCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      @endpoint RealtimeChatServerWeb.Endpoint

      use RealtimeChatServerWeb, :verified_routes

      import Phoenix.ChannelTest
      import RealtimeChatServerWeb.ChannelCase
    end
  end
end
