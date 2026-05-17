defmodule DistributedNotificationPlatform do
  @moduledoc """
  Distributed notification platform with pub/sub delivery and retries.
  """

  alias DistributedNotificationPlatform.{Receiver, Router}

  def start_receiver(receiver_id, opts \\ []) do
    child =
      {Receiver, receiver_id: receiver_id, failure_budget: Keyword.get(opts, :failure_budget, 0)}

    case DynamicSupervisor.start_child(DistributedNotificationPlatform.ReceiverSupervisor, child) do
      {:ok, _pid} -> :ok
      {:error, {:already_started, _pid}} -> {:error, :already_started}
      error -> error
    end
  end

  def stop_receiver(receiver_id) do
    case Receiver.whereis(receiver_id) do
      nil ->
        :ok

      pid ->
        DynamicSupervisor.terminate_child(DistributedNotificationPlatform.ReceiverSupervisor, pid)
    end
  end

  def subscribe(receiver_id, topic) do
    case Receiver.whereis(receiver_id) do
      nil -> {:error, :receiver_not_found}
      pid -> Receiver.subscribe(pid, topic)
    end
  end

  def unsubscribe(receiver_id, topic) do
    case Receiver.whereis(receiver_id) do
      nil -> {:error, :receiver_not_found}
      pid -> Receiver.unsubscribe(pid, topic)
    end
  end

  def notifications(receiver_id) do
    case Receiver.whereis(receiver_id) do
      nil -> {:error, :receiver_not_found}
      pid -> {:ok, Receiver.notifications(pid)}
    end
  end

  def publish(topic, payload, opts \\ []) do
    Router.publish(topic, payload, opts)
  end

  def stats, do: Router.stats()
  def node_info, do: %{current_node: node(), connected_nodes: Node.list()}
  def connect_node(node_name), do: Node.connect(node_name)
  def disconnect_node(node_name), do: Node.disconnect(node_name)
  def reset, do: Router.reset()
end
