defmodule DistributedNotificationPlatform.Receiver do
  @moduledoc false
  use GenServer, restart: :temporary

  def start_link(opts) do
    receiver_id = Keyword.fetch!(opts, :receiver_id)
    failure_budget = Keyword.get(opts, :failure_budget, 0)

    GenServer.start_link(__MODULE__, %{receiver_id: receiver_id, failure_budget: failure_budget},
      name: global_name(receiver_id)
    )
  end

  def whereis(receiver_id), do: :global.whereis_name(global_key(receiver_id))
  def subscribe(pid, topic), do: GenServer.call(pid, {:subscribe, topic})
  def unsubscribe(pid, topic), do: GenServer.call(pid, {:unsubscribe, topic})
  def notifications(pid), do: GenServer.call(pid, :notifications)
  def deliver(pid, notification), do: GenServer.call(pid, {:deliver, notification}, 1_000)

  @impl true
  def init(state) do
    {:ok, Map.put(state, :notifications, [])}
  end

  @impl true
  def handle_call({:subscribe, topic}, _from, state) do
    :ok = :pg.join(pg_scope(), topic_group(topic), self())
    {:reply, :ok, state}
  end

  def handle_call({:unsubscribe, topic}, _from, state) do
    :ok = :pg.leave(pg_scope(), topic_group(topic), self())
    {:reply, :ok, state}
  end

  def handle_call(:notifications, _from, state) do
    {:reply, Enum.reverse(state.notifications), state}
  end

  def handle_call({:deliver, notification}, _from, state) do
    if state.failure_budget > 0 do
      {:reply, {:error, :temporary_failure}, %{state | failure_budget: state.failure_budget - 1}}
    else
      {:reply, :ok, %{state | notifications: [notification | state.notifications]}}
    end
  end

  defp topic_group(topic), do: {:notification_topic, topic}
  defp pg_scope, do: DistributedNotificationPlatform.PubSub
  defp global_name(receiver_id), do: {:global, global_key(receiver_id)}
  defp global_key(receiver_id), do: {:distributed_notification_receiver, receiver_id}
end
