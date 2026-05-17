defmodule LiveDashboardSystem.MetricsTest do
  use ExUnit.Case, async: false

  alias LiveDashboardSystem.Metrics

  test "snapshot returns metric samples" do
    samples = Metrics.snapshot()

    assert is_list(samples)
    assert length(samples) >= 1

    latest = List.last(samples)
    assert is_integer(latest.cpu)
    assert is_integer(latest.memory)
    assert is_integer(latest.requests)
    assert is_binary(latest.timestamp)
  end

  test "publishes updates through pubsub" do
    Metrics.subscribe()
    Metrics.tick()

    assert_receive {:metrics_update, samples}, 1_000
    assert is_list(samples)
    assert length(samples) >= 1
  end
end
