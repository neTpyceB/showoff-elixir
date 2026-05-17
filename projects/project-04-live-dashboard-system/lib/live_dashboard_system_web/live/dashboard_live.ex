defmodule LiveDashboardSystemWeb.DashboardLive do
  use LiveDashboardSystemWeb, :live_view

  alias LiveDashboardSystem.Metrics

  @chart_width 720
  @chart_height 220

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: Metrics.subscribe()

    samples = Metrics.snapshot()

    {:ok,
     socket
     |> assign(:chart_width, @chart_width)
     |> assign(:chart_height, @chart_height)
     |> assign(:samples, samples)
     |> assign_chart()}
  end

  @impl true
  def handle_info({:metrics_update, samples}, socket) do
    {:noreply,
     socket
     |> assign(:samples, samples)
     |> assign_chart()}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <main class="mx-auto max-w-6xl p-6 space-y-6">
      <header class="space-y-2">
        <h1 class="text-3xl font-bold">Live Dashboard System</h1>
        <p class="text-sm text-base-content/70">
          Realtime UI with LiveView + PubSub state synchronization.
        </p>
      </header>

      <section class="grid gap-4 sm:grid-cols-3">
        <article class="card bg-base-200">
          <div class="card-body">
            <h2 class="card-title text-base">CPU</h2>
            <p class="text-4xl font-semibold">{@latest.cpu}%</p>
          </div>
        </article>
        <article class="card bg-base-200">
          <div class="card-body">
            <h2 class="card-title text-base">Memory</h2>
            <p class="text-4xl font-semibold">{@latest.memory}%</p>
          </div>
        </article>
        <article class="card bg-base-200">
          <div class="card-body">
            <h2 class="card-title text-base">Requests/min</h2>
            <p class="text-4xl font-semibold">{@latest.requests}</p>
            <p class="text-xs text-base-content/70">Synced at {@latest.timestamp}</p>
          </div>
        </article>
      </section>

      <section class="card bg-base-200">
        <div class="card-body">
          <h2 class="card-title text-base">Realtime Graph</h2>
          <svg
            viewBox={"0 0 #{@chart_width} #{@chart_height}"}
            class="w-full rounded-lg bg-base-100 p-2"
          >
            <polyline fill="none" stroke="#f97316" stroke-width="3" points={@cpu_points} />
            <polyline fill="none" stroke="#06b6d4" stroke-width="3" points={@memory_points} />
          </svg>
          <p class="text-xs text-base-content/70">Orange: CPU | Cyan: Memory</p>
        </div>
      </section>
    </main>
    """
  end

  defp assign_chart(socket) do
    samples = socket.assigns.samples
    latest = List.last(samples) || %{cpu: 0, memory: 0, requests: 0, timestamp: "-"}

    socket
    |> assign(:latest, latest)
    |> assign(:cpu_points, points_for(samples, :cpu, 100))
    |> assign(:memory_points, points_for(samples, :memory, 100))
  end

  defp points_for([], _field, _max), do: "0,220"

  defp points_for([sample], field, max_value) do
    y = y_pos(Map.fetch!(sample, field), max_value)
    "0,#{y}"
  end

  defp points_for(samples, field, max_value) do
    last_index = length(samples) - 1

    samples
    |> Enum.with_index()
    |> Enum.map_join(" ", fn {sample, index} ->
      x = index * (@chart_width - 1) / last_index
      y = y_pos(Map.fetch!(sample, field), max_value)
      "#{Float.round(x, 1)},#{y}"
    end)
  end

  defp y_pos(value, max_value) do
    scaled = @chart_height - value * @chart_height / max_value
    Float.round(scaled, 1)
  end
end
