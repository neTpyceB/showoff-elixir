defmodule WorldScaleDistributedPlatform.Platform do
  @moduledoc false
  use GenServer

  alias WorldScaleDistributedPlatform.Gateway

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def simulate_connections(total_connections, gateway_count),
    do: GenServer.call(__MODULE__, {:simulate_connections, total_connections, gateway_count})

  def subscribe_channel(channel), do: :pg.join(scope(), {:channel, channel}, self())
  def subscribe_events(topic), do: :pg.join(scope(), {:events, topic}, self())

  def publish_message(channel, payload),
    do: GenServer.call(__MODULE__, {:publish_message, channel, payload})

  def publish_event(topic, payload),
    do: GenServer.call(__MODULE__, {:publish_event, topic, payload})

  def trigger_gateway_failure(gateway_id),
    do: GenServer.call(__MODULE__, {:trigger_gateway_failure, gateway_id})

  def run_resilience_test(gateway_id),
    do: GenServer.call(__MODULE__, {:run_resilience_test, gateway_id})

  def stats, do: GenServer.call(__MODULE__, :stats)
  def gateway_stats(gateway_id), do: GenServer.call(__MODULE__, {:gateway_stats, gateway_id})
  def reset, do: GenServer.call(__MODULE__, :reset)

  @impl true
  def init(opts) do
    initial_gateways = Keyword.get(opts, :initial_gateways, 4)

    state = %{
      initial_gateways: initial_gateways,
      gateway_ids: MapSet.new(),
      gateway_start_count: %{},
      virtual_connections_total: 0,
      published_messages: 0,
      delivered_messages: 0,
      published_events: 0,
      delivered_events: 0,
      recoveries: 0,
      next_message_id: 1,
      next_event_id: 1
    }

    {:ok, ensure_gateways(state, initial_gateways)}
  end

  @impl true
  def handle_call({:simulate_connections, total_connections, gateway_count}, _from, state) do
    state = ensure_gateways(state, gateway_count)
    shares = split_connections(total_connections, gateway_count)

    shares
    |> Enum.with_index(1)
    |> Enum.each(fn {count, gateway_id} ->
      Gateway.set_virtual_connections(gateway_id, count)
    end)

    state.gateway_ids
    |> MapSet.to_list()
    |> Enum.filter(&(&1 > gateway_count))
    |> Enum.each(fn gateway_id ->
      Gateway.set_virtual_connections(gateway_id, 0)
    end)

    state = %{state | virtual_connections_total: total_connections}
    {:reply, %{total_connections: total_connections, gateway_count: gateway_count}, state}
  end

  def handle_call({:publish_message, channel, payload}, _from, state) do
    message = %{
      id: state.next_message_id,
      channel: channel,
      payload: payload,
      at: now_iso(),
      node: node()
    }

    members = safe_members({:channel, channel})

    Enum.each(members, fn pid ->
      send(pid, {:realtime_message, channel, message})
    end)

    state.gateway_ids
    |> MapSet.to_list()
    |> Enum.each(fn gateway_id ->
      Gateway.deliver(gateway_id, message)
    end)

    delivered = length(members)

    state = %{
      state
      | next_message_id: state.next_message_id + 1,
        published_messages: state.published_messages + 1,
        delivered_messages: state.delivered_messages + delivered
    }

    {:reply, {:ok, message}, state}
  end

  def handle_call({:publish_event, topic, payload}, _from, state) do
    event = %{
      id: state.next_event_id,
      topic: topic,
      payload: payload,
      at: now_iso(),
      node: node()
    }

    members = safe_members({:events, topic})

    Enum.each(members, fn pid ->
      send(pid, {:distributed_event, topic, event})
    end)

    state = %{
      state
      | next_event_id: state.next_event_id + 1,
        published_events: state.published_events + 1,
        delivered_events: state.delivered_events + length(members)
    }

    {:reply, {:ok, event}, state}
  end

  def handle_call({:trigger_gateway_failure, gateway_id}, _from, state) do
    case Gateway.whereis(gateway_id) do
      nil ->
        {:reply, {:error, :gateway_not_found}, state}

      pid ->
        Process.exit(pid, :kill)
        {:reply, :ok, state}
    end
  end

  def handle_call({:run_resilience_test, gateway_id}, _from, state) do
    case Gateway.whereis(gateway_id) do
      nil ->
        {:reply, {:error, :gateway_not_found}, state}

      old_pid ->
        Process.exit(old_pid, :kill)
        new_pid = wait_for_recovery(gateway_id, old_pid, 40)

        {:reply,
         %{
           gateway_id: gateway_id,
           old_pid: old_pid,
           new_pid: new_pid,
           recovered: is_pid(new_pid) and new_pid != old_pid
         }, state}
    end
  end

  def handle_call({:gateway_stats, gateway_id}, _from, state) do
    reply =
      case Gateway.whereis(gateway_id) do
        nil -> {:error, :gateway_not_found}
        _pid -> {:ok, Gateway.stats(gateway_id)}
      end

    {:reply, reply, state}
  end

  def handle_call(:stats, _from, state) do
    {:reply,
     %{
       gateway_count: MapSet.size(state.gateway_ids),
       virtual_connections_total: state.virtual_connections_total,
       published_messages: state.published_messages,
       delivered_messages: state.delivered_messages,
       published_events: state.published_events,
       delivered_events: state.delivered_events,
       recoveries: state.recoveries,
       connected_nodes: Node.list()
     }, state}
  end

  def handle_call(:reset, _from, state) do
    DynamicSupervisor.which_children(WorldScaleDistributedPlatform.GatewaySupervisor)
    |> Enum.each(fn {_id, pid, _type, _modules} ->
      DynamicSupervisor.terminate_child(WorldScaleDistributedPlatform.GatewaySupervisor, pid)
    end)

    base_state = %{
      state
      | gateway_ids: MapSet.new(),
        gateway_start_count: %{},
        virtual_connections_total: 0,
        published_messages: 0,
        delivered_messages: 0,
        published_events: 0,
        delivered_events: 0,
        recoveries: 0,
        next_message_id: 1,
        next_event_id: 1
    }

    {:reply, :ok, ensure_gateways(base_state, state.initial_gateways)}
  end

  @impl true
  def handle_info({:gateway_started, gateway_id, _pid}, state) do
    count = Map.get(state.gateway_start_count, gateway_id, 0) + 1
    recoveries = if count > 1, do: state.recoveries + 1, else: state.recoveries

    state = %{
      state
      | gateway_ids: MapSet.put(state.gateway_ids, gateway_id),
        gateway_start_count: Map.put(state.gateway_start_count, gateway_id, count),
        recoveries: recoveries
    }

    {:noreply, state}
  end

  defp ensure_gateways(state, gateway_count) do
    1..gateway_count
    |> Enum.reduce(state, fn gateway_id, acc ->
      acc = %{acc | gateway_ids: MapSet.put(acc.gateway_ids, gateway_id)}

      case Gateway.whereis(gateway_id) do
        nil ->
          case DynamicSupervisor.start_child(
                 WorldScaleDistributedPlatform.GatewaySupervisor,
                 {Gateway, gateway_id}
               ) do
            {:ok, _pid} -> acc
            {:error, {:already_started, _pid}} -> acc
            _ -> acc
          end

        _pid ->
          acc
      end
    end)
  end

  defp split_connections(total, parts) do
    base = div(total, parts)
    remainder = rem(total, parts)

    Enum.map(1..parts, fn idx ->
      if idx <= remainder, do: base + 1, else: base
    end)
  end

  defp safe_members(group) do
    try do
      :pg.get_members(scope(), group)
    catch
      :exit, _ -> []
    end
  end

  defp wait_for_recovery(_gateway_id, _old_pid, 0), do: nil

  defp wait_for_recovery(gateway_id, old_pid, attempts_left) do
    case Gateway.whereis(gateway_id) do
      nil ->
        Process.sleep(10)
        wait_for_recovery(gateway_id, old_pid, attempts_left - 1)

      pid when pid == old_pid ->
        Process.sleep(10)
        wait_for_recovery(gateway_id, old_pid, attempts_left - 1)

      pid ->
        pid
    end
  end

  defp scope, do: WorldScaleDistributedPlatform.PubSubScope

  defp now_iso do
    DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601()
  end
end
