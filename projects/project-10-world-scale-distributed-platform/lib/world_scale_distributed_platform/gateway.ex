defmodule WorldScaleDistributedPlatform.Gateway do
  @moduledoc false
  use GenServer

  def start_link(gateway_id) do
    GenServer.start_link(__MODULE__, gateway_id, name: via(gateway_id))
  end

  def whereis(gateway_id) do
    case Registry.lookup(WorldScaleDistributedPlatform.GatewayRegistry, gateway_id) do
      [{pid, _}] -> pid
      [] -> nil
    end
  end

  def set_virtual_connections(gateway_id, count),
    do: GenServer.call(via(gateway_id), {:set_virtual_connections, count})

  def deliver(gateway_id, message), do: GenServer.cast(via(gateway_id), {:deliver, message})
  def stats(gateway_id), do: GenServer.call(via(gateway_id), :stats)

  @impl true
  def init(gateway_id) do
    send(WorldScaleDistributedPlatform.Platform, {:gateway_started, gateway_id, self()})

    {:ok,
     %{gateway_id: gateway_id, virtual_connections: 0, handled_messages: 0, last_message: nil}}
  end

  @impl true
  def handle_call({:set_virtual_connections, count}, _from, state) do
    {:reply, :ok, %{state | virtual_connections: count}}
  end

  def handle_call(:stats, _from, state), do: {:reply, state, state}

  @impl true
  def handle_cast({:deliver, message}, state) do
    {:noreply, %{state | handled_messages: state.handled_messages + 1, last_message: message}}
  end

  defp via(gateway_id) do
    {:via, Registry, {WorldScaleDistributedPlatform.GatewayRegistry, gateway_id}}
  end
end
