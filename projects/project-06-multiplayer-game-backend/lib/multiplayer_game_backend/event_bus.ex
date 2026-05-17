defmodule MultiplayerGameBackend.EventBus do
  @moduledoc false

  @registry MultiplayerGameBackend.EventRegistry

  def subscribe(topic) do
    Registry.register(@registry, topic, [])
  end

  def broadcast(topic, event) do
    Registry.dispatch(@registry, topic, fn entries ->
      Enum.each(entries, fn {pid, _value} ->
        send(pid, {:realtime_event, topic, event})
      end)
    end)

    :ok
  end
end
