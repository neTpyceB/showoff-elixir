defmodule LiveDashboardSystem.Metrics do
  @moduledoc false
  use GenServer

  @topic "metrics:live"
  @history_size 40
  @tick_ms 1_000

  @type sample :: %{
          sequence: pos_integer(),
          cpu: non_neg_integer(),
          memory: non_neg_integer(),
          requests: non_neg_integer(),
          timestamp: String.t()
        }

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def subscribe do
    Phoenix.PubSub.subscribe(LiveDashboardSystem.PubSub, @topic)
  end

  def snapshot do
    GenServer.call(__MODULE__, :snapshot)
  end

  def tick do
    GenServer.cast(__MODULE__, :tick)
  end

  @impl true
  def init(_opts) do
    state = %{sequence: 0, samples: []}
    state = add_sample(state)
    schedule_tick()
    {:ok, state}
  end

  @impl true
  def handle_call(:snapshot, _from, state) do
    {:reply, state.samples, state}
  end

  @impl true
  def handle_cast(:tick, state) do
    state = add_sample(state)
    broadcast(state.samples)
    {:noreply, state}
  end

  @impl true
  def handle_info(:tick, state) do
    state = add_sample(state)
    broadcast(state.samples)
    schedule_tick()
    {:noreply, state}
  end

  defp schedule_tick do
    Process.send_after(self(), :tick, @tick_ms)
  end

  defp add_sample(state) do
    next_sequence = state.sequence + 1

    sample = %{
      sequence: next_sequence,
      cpu: :rand.uniform(100),
      memory: :rand.uniform(100),
      requests: 50 + :rand.uniform(450),
      timestamp: DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601()
    }

    %{state | sequence: next_sequence, samples: trim_samples(state.samples ++ [sample])}
  end

  defp trim_samples(samples) do
    drop = max(length(samples) - @history_size, 0)
    Enum.drop(samples, drop)
  end

  defp broadcast(samples) do
    Phoenix.PubSub.broadcast(LiveDashboardSystem.PubSub, @topic, {:metrics_update, samples})
  end
end
