defmodule FaultTolerantJobProcessingSystem.Server do
  @moduledoc false
  use GenServer

  alias FaultTolerantJobProcessingSystem.Worker

  @default_max_workers 3
  @default_max_retries 2

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def enqueue(payload, opts \\ []) do
    GenServer.call(__MODULE__, {:enqueue, payload, opts})
  end

  def stats do
    GenServer.call(__MODULE__, :stats)
  end

  def results do
    GenServer.call(__MODULE__, :results)
  end

  def reset do
    GenServer.call(__MODULE__, :reset)
  end

  @impl true
  def init(opts) do
    {:ok,
     %{
       next_id: 1,
       max_workers: Keyword.get(opts, :max_workers, @default_max_workers),
       default_max_retries: Keyword.get(opts, :default_max_retries, @default_max_retries),
       pending: :queue.new(),
       in_progress: %{},
       results: %{}
     }}
  end

  @impl true
  def handle_call({:enqueue, payload, opts}, _from, state) do
    max_retries = Keyword.get(opts, :max_retries, state.default_max_retries)

    job = %{
      id: state.next_id,
      payload: payload,
      attempt: 1,
      max_retries: max_retries
    }

    state =
      state
      |> Map.update!(:next_id, &(&1 + 1))
      |> enqueue_job(job)
      |> dispatch_jobs()

    {:reply, {:ok, job.id}, state}
  end

  def handle_call(:stats, _from, state) do
    stats = %{
      pending: :queue.len(state.pending),
      in_progress: map_size(state.in_progress),
      completed: count_results(state.results, :ok),
      failed: count_results(state.results, :error)
    }

    {:reply, stats, state}
  end

  def handle_call(:results, _from, state) do
    data =
      state.results
      |> Enum.map(fn {job_id, result} -> %{job_id: job_id, result: result} end)
      |> Enum.sort_by(& &1.job_id)

    {:reply, data, state}
  end

  def handle_call(:reset, _from, state) do
    Enum.each(state.in_progress, fn {_job_id, %{pid: pid}} ->
      DynamicSupervisor.terminate_child(FaultTolerantJobProcessingSystem.WorkerSupervisor, pid)
    end)

    new_state = %{state | pending: :queue.new(), in_progress: %{}, results: %{}}
    {:reply, :ok, new_state}
  end

  @impl true
  def handle_info({:job_completed, pid, job, result}, state) do
    case take_in_progress_by_pid(state, pid) do
      {nil, state} ->
        {:noreply, state}

      {_entry, state} ->
        state =
          case result do
            {:ok, value} -> put_result(state, job.id, {:ok, value})
            {:error, reason} -> retry_or_fail(state, job, reason)
          end

        {:noreply, dispatch_jobs(state)}
    end
  end

  def handle_info({:DOWN, ref, :process, _pid, reason}, state) do
    case pop_in_progress_by_ref(state, ref) do
      {nil, state} ->
        {:noreply, state}

      {%{job: job}, state} ->
        state = if reason == :normal, do: state, else: retry_or_fail(state, job, reason)
        {:noreply, dispatch_jobs(state)}
    end
  end

  defp dispatch_jobs(state) do
    cond do
      map_size(state.in_progress) >= state.max_workers ->
        state

      :queue.is_empty(state.pending) ->
        state

      true ->
        {{:value, job}, pending} = :queue.out(state.pending)

        case DynamicSupervisor.start_child(
               FaultTolerantJobProcessingSystem.WorkerSupervisor,
               %{
                 id: {Worker, job.id, job.attempt},
                 start: {Worker, :start_link, [[manager: self(), job: job]]},
                 restart: :temporary
               }
             ) do
          {:ok, pid} ->
            ref = Process.monitor(pid)

            state
            |> Map.put(:pending, pending)
            |> put_in_progress(job.id, pid, ref, job)
            |> dispatch_jobs()

          {:error, _reason} ->
            state
        end
    end
  end

  defp enqueue_job(state, job) do
    %{state | pending: :queue.in(job, state.pending)}
  end

  defp put_in_progress(state, job_id, pid, ref, job) do
    entry = %{pid: pid, ref: ref, job: job}
    put_in(state.in_progress[job_id], entry)
  end

  defp take_in_progress_by_pid(state, pid) do
    case Enum.find(state.in_progress, fn {_job_id, entry} -> entry.pid == pid end) do
      nil ->
        {nil, state}

      {job_id, entry} ->
        Process.demonitor(entry.ref, [:flush])
        {entry, %{state | in_progress: Map.delete(state.in_progress, job_id)}}
    end
  end

  defp pop_in_progress_by_ref(state, ref) do
    case Enum.find(state.in_progress, fn {_job_id, entry} -> entry.ref == ref end) do
      nil ->
        {nil, state}

      {job_id, entry} ->
        {entry, %{state | in_progress: Map.delete(state.in_progress, job_id)}}
    end
  end

  defp retry_or_fail(state, job, reason) do
    if job.attempt <= job.max_retries do
      enqueue_job(state, %{job | attempt: job.attempt + 1})
    else
      put_result(state, job.id, {:error, reason})
    end
  end

  defp put_result(state, job_id, result) do
    %{state | results: Map.put(state.results, job_id, result)}
  end

  defp count_results(results, status) do
    Enum.count(results, fn {_job_id, {key, _value}} -> key == status end)
  end
end
