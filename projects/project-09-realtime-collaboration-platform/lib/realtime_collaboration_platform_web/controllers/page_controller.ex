defmodule RealtimeCollaborationPlatformWeb.PageController do
  use RealtimeCollaborationPlatformWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
