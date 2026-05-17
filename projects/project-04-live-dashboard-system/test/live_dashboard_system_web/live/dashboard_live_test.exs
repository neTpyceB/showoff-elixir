defmodule LiveDashboardSystemWeb.DashboardLiveTest do
  use LiveDashboardSystemWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  test "renders and syncs updates", %{conn: conn} do
    {:ok, view, html} = live(conn, "/")

    assert html =~ "Live Dashboard System"

    Phoenix.PubSub.broadcast(
      LiveDashboardSystem.PubSub,
      "metrics:live",
      {:metrics_update,
       [
         %{sequence: 1, cpu: 10, memory: 20, requests: 120, timestamp: "2026-01-01T00:00:00Z"},
         %{sequence: 2, cpu: 77, memory: 55, requests: 350, timestamp: "2026-01-01T00:00:01Z"}
       ]}
    )

    rendered = render(view)
    assert rendered =~ "77%"
    assert rendered =~ "55%"
    assert rendered =~ "350"
  end
end
