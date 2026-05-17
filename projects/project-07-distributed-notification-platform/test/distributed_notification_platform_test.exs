defmodule DistributedNotificationPlatformTest do
  use ExUnit.Case, async: false

  alias DistributedNotificationPlatform, as: Platform

  setup do
    Platform.reset()
    :ok
  end

  test "pub/sub notification delivery" do
    assert :ok = Platform.start_receiver("receiver-1")
    assert :ok = Platform.start_receiver("receiver-2")
    assert :ok = Platform.subscribe("receiver-1", "orders")
    assert :ok = Platform.subscribe("receiver-2", "orders")

    assert {:ok, [_, _]} = Platform.publish("orders", %{event: "created", id: 100})

    assert_eventually(fn ->
      {:ok, messages_1} = Platform.notifications("receiver-1")
      {:ok, messages_2} = Platform.notifications("receiver-2")
      length(messages_1) == 1 and length(messages_2) == 1
    end)

    {:ok, [msg_1]} = Platform.notifications("receiver-1")
    {:ok, [msg_2]} = Platform.notifications("receiver-2")

    assert msg_1.topic == "orders"
    assert msg_2.topic == "orders"
    assert msg_1.payload == %{event: "created", id: 100}
    assert msg_2.payload == %{event: "created", id: 100}
  end

  test "retry delivery succeeds after transient failure" do
    assert :ok = Platform.start_receiver("receiver-retry", failure_budget: 1)
    assert :ok = Platform.subscribe("receiver-retry", "billing")

    assert {:ok, [_id]} = Platform.publish("billing", %{event: "charged", id: 7})

    assert_eventually(fn ->
      {:ok, messages} = Platform.notifications("receiver-retry")
      length(messages) == 1
    end)

    {:ok, [message]} = Platform.notifications("receiver-retry")
    assert message.attempt == 2
    assert %{retried: retried} = Platform.stats()
    assert retried >= 1
  end

  test "delivery fails when retries are exhausted" do
    assert :ok = Platform.start_receiver("receiver-fail", failure_budget: 10)
    assert :ok = Platform.subscribe("receiver-fail", "alerts")

    assert {:ok, [_id]} =
             Platform.publish("alerts", %{event: "down"}, max_retries: 1, retry_delay_ms: 5)

    assert_eventually(fn ->
      %{failed: failed, pending: pending} = Platform.stats()
      failed == 1 and pending == 0
    end)

    {:ok, messages} = Platform.notifications("receiver-fail")
    assert messages == []
  end

  test "node metadata is exposed" do
    assert %{current_node: current_node, connected_nodes: connected_nodes} = Platform.node_info()
    assert current_node == node()
    assert is_list(connected_nodes)
  end

  defp assert_eventually(fun, attempts \\ 30)

  defp assert_eventually(fun, 0), do: assert(fun.())

  defp assert_eventually(fun, attempts) do
    if fun.() do
      assert true
    else
      Process.sleep(20)
      assert_eventually(fun, attempts - 1)
    end
  end
end
