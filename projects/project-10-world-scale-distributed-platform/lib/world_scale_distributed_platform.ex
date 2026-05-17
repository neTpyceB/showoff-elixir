defmodule WorldScaleDistributedPlatform do
  @moduledoc """
  World-scale distributed platform simulation runtime.
  """

  alias WorldScaleDistributedPlatform.Platform

  def simulate_connections(total_connections, gateway_count \\ 8),
    do: Platform.simulate_connections(total_connections, gateway_count)

  def subscribe_channel(channel), do: Platform.subscribe_channel(channel)
  def publish_message(channel, payload), do: Platform.publish_message(channel, payload)

  def subscribe_events(topic), do: Platform.subscribe_events(topic)
  def publish_event(topic, payload), do: Platform.publish_event(topic, payload)

  def trigger_gateway_failure(gateway_id), do: Platform.trigger_gateway_failure(gateway_id)
  def run_resilience_test(gateway_id), do: Platform.run_resilience_test(gateway_id)

  def stats, do: Platform.stats()
  def gateway_stats(gateway_id), do: Platform.gateway_stats(gateway_id)

  def node_info, do: %{current_node: node(), connected_nodes: Node.list()}
  def connect_node(node_name), do: Node.connect(node_name)
  def disconnect_node(node_name), do: Node.disconnect(node_name)

  def reset, do: Platform.reset()
end
