defmodule FaultTolerantJobProcessingSystem.Worker do
  @moduledoc false
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  @impl true
  def init(opts) do
    send(self(), :run)

    {:ok,
     %{
       manager: Keyword.fetch!(opts, :manager),
       job: Keyword.fetch!(opts, :job)
     }}
  end

  @impl true
  def handle_info(:run, state) do
    job = state.job

    case execute(job) do
      {:ok, result} ->
        send(state.manager, {:job_completed, self(), job, {:ok, result}})
        {:stop, :normal, state}

      {:error, reason} ->
        send(state.manager, {:job_completed, self(), job, {:error, reason}})
        {:stop, :normal, state}

      :crash ->
        raise "job #{job.id} crashed"
    end
  end

  defp execute(%{payload: %{mode: :ok, value: value}}), do: {:ok, value}

  defp execute(%{payload: %{mode: :sleep_ok, ms: ms, value: value}}) do
    Process.sleep(ms)
    {:ok, value}
  end

  defp execute(%{payload: %{mode: :error, reason: reason}}), do: {:error, reason}

  defp execute(%{payload: %{mode: :crash}}), do: :crash

  defp execute(%{payload: %{mode: :flaky_crash, fail_attempts: fail_attempts, value: value}, attempt: attempt}) do
    if attempt <= fail_attempts, do: :crash, else: {:ok, value}
  end
end
