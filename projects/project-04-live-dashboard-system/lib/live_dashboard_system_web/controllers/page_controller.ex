defmodule LiveDashboardSystemWeb.PageController do
  use LiveDashboardSystemWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
