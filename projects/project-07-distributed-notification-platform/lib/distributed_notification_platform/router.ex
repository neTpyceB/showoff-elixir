defmodule DistributedNotificationPlatform.Router do
  @moduledoc false
  use GenServer

  alias DistributedNotificationPlatform.DeliveryWorker

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def publish(topic, payload, opts \\ []) do
    GenServer.call(__MODULE__, {:publish, topic, payload, opts})
  end

  def stats, do: GenServer.call(__MODULE__, :stats)
  def reset, do: GenServer.call(__MODULE__, :reset)

  @impl true
  def init(opts) do
    {:ok,
     %{
       next_id: 1,
       max_retries: Keyword.get(opts, :max_retries, 2),
       retry_delay_ms: Keyword.get(opts, :retry_delay_ms, 50),
       published: 0,
       delivered: 0,
       failed: 0,
       retried: 0,
       pending: 0
     }}
  end

  @impl true
  def handle_call({:publish, topic, payload, opts}, _from, state) do
    members =
      topic
      |> topic_group()
      |> safe_group_members()
      |> Enum.uniq()

    max_retries = Keyword.get(opts, :max_retries, state.max_retries)
    retry_delay_ms = Keyword.get(opts, :retry_delay_ms, state.retry_delay_ms)
    max_attempts = max_retries + 1

    {ids, next_id} =
      Enum.map_reduce(members, state.next_id, fn target_pid, id ->
        notification = %{id: id, topic: topic, payload: payload}

        _ =
          case DynamicSupervisor.start_child(
                 DistributedNotificationPlatform.DeliverySupervisor,
                 {DeliveryWorker,
                  router: self(),
                  target_pid: target_pid,
                  notification: notification,
                  max_attempts: max_attempts,
                  retry_delay_ms: retry_delay_ms}
               ) do
            {:ok, _pid} -> :ok
            {:error, _reason} -> :error
          end

        {id, id + 1}
      end)

    new_state = %{
      state
      | next_id: next_id,
        published: state.published + length(ids),
        pending: state.pending + length(ids)
    }

    {:reply, {:ok, ids}, new_state}
  end

  def handle_call(:stats, _from, state), do: {:reply, Map.take(state, stat_keys()), state}

  def handle_call(:reset, _from, state) do
    :ok =
      DynamicSupervisor.which_children(DistributedNotificationPlatform.ReceiverSupervisor)
      |> Enum.each(fn {_id, pid, _type, _modules} ->
        DynamicSupervisor.terminate_child(DistributedNotificationPlatform.ReceiverSupervisor, pid)
      end)

    :ok =
      DynamicSupervisor.which_children(DistributedNotificationPlatform.DeliverySupervisor)
      |> Enum.each(fn {_id, pid, _type, _modules} ->
        DynamicSupervisor.terminate_child(DistributedNotificationPlatform.DeliverySupervisor, pid)
      end)

    {:reply, :ok,
     %{
       state
       | next_id: 1,
         published: 0,
         delivered: 0,
         failed: 0,
         retried: 0,
         pending: 0
     }}
  end

  @impl true
  def handle_info({:delivery_result, :ok, _id, _target_pid, _attempt}, state) do
    {:noreply, %{state | delivered: state.delivered + 1, pending: state.pending - 1}}
  end

  def handle_info({:delivery_result, :retry, _id, _target_pid, _attempt, _reason}, state) do
    {:noreply, %{state | retried: state.retried + 1}}
  end

  def handle_info({:delivery_result, :failed, _id, _target_pid, _attempt, _reason}, state) do
    {:noreply, %{state | failed: state.failed + 1, pending: state.pending - 1}}
  end

  defp topic_group(topic), do: {:notification_topic, topic}
  defp stat_keys, do: [:published, :delivered, :failed, :retried, :pending]

  defp safe_group_members(group) do
    try do
      :pg.get_members(DistributedNotificationPlatform.PubSub, group)
    catch
      :exit, _ -> []
    end
  end
end
