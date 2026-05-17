defmodule DistributedNotificationPlatform.DeliveryWorker do
  @moduledoc false
  use GenServer, restart: :temporary

  alias DistributedNotificationPlatform.Receiver

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  @impl true
  def init(opts) do
    state = %{
      router: Keyword.fetch!(opts, :router),
      target_pid: Keyword.fetch!(opts, :target_pid),
      notification: Keyword.fetch!(opts, :notification),
      retry_delay_ms: Keyword.fetch!(opts, :retry_delay_ms),
      max_attempts: Keyword.fetch!(opts, :max_attempts),
      attempt: 1
    }

    send(self(), :deliver)
    {:ok, state}
  end

  @impl true
  def handle_info(:deliver, state) do
    notification = Map.put(state.notification, :attempt, state.attempt)

    case deliver(state.target_pid, notification) do
      :ok ->
        send(
          state.router,
          {:delivery_result, :ok, notification.id, state.target_pid, state.attempt}
        )

        {:stop, :normal, state}

      {:error, reason} when state.attempt < state.max_attempts ->
        send(
          state.router,
          {:delivery_result, :retry, notification.id, state.target_pid, state.attempt, reason}
        )

        Process.send_after(self(), :deliver, state.retry_delay_ms)
        {:noreply, %{state | attempt: state.attempt + 1}}

      {:error, reason} ->
        send(
          state.router,
          {:delivery_result, :failed, notification.id, state.target_pid, state.attempt, reason}
        )

        {:stop, :normal, state}
    end
  end

  defp deliver(target_pid, notification) do
    try do
      case Receiver.deliver(target_pid, notification) do
        :ok -> :ok
        {:error, reason} -> {:error, reason}
      end
    catch
      :exit, reason -> {:error, reason}
    end
  end
end
