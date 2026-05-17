defmodule FaultTolerantJobProcessingSystemTest do
  use ExUnit.Case, async: false

  alias FaultTolerantJobProcessingSystem, as: JobSystem

  setup do
    JobSystem.reset()
    :ok
  end

  test "processes jobs successfully" do
    {:ok, _id1} = JobSystem.submit(%{mode: :ok, value: "a"})
    {:ok, _id2} = JobSystem.submit(%{mode: :ok, value: "b"})

    wait_for(fn -> JobSystem.stats().completed == 2 end)

    assert %{completed: 2, failed: 0} = JobSystem.stats()
  end

  test "retries crashed jobs and recovers" do
    {:ok, job_id} = JobSystem.submit(%{mode: :flaky_crash, fail_attempts: 1, value: "done"}, max_retries: 2)

    wait_for(fn -> JobSystem.stats().completed == 1 end)

    assert [%{job_id: ^job_id, result: {:ok, "done"}}] = JobSystem.results()
  end

  test "marks job as failed after retries exhausted" do
    {:ok, job_id} = JobSystem.submit(%{mode: :crash}, max_retries: 1)

    wait_for(fn -> JobSystem.stats().failed == 1 end)

    assert [%{job_id: ^job_id, result: {:error, _reason}}] = JobSystem.results()
  end

  test "worker pool runs jobs concurrently" do
    start = System.monotonic_time(:millisecond)

    Enum.each(1..3, fn index ->
      {:ok, _id} = JobSystem.submit(%{mode: :sleep_ok, ms: 150, value: index})
    end)

    wait_for(fn -> JobSystem.stats().completed == 3 end)

    elapsed = System.monotonic_time(:millisecond) - start
    assert elapsed < 350
  end

  defp wait_for(fun, attempts \\ 50)

  defp wait_for(_fun, 0), do: flunk("condition not reached in time")

  defp wait_for(fun, attempts) do
    if fun.() do
      :ok
    else
      Process.sleep(25)
      wait_for(fun, attempts - 1)
    end
  end
end
