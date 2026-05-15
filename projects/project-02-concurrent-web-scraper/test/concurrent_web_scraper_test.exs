defmodule ConcurrentWebScraperTest do
  use ExUnit.Case, async: true

  test "fetches many urls concurrently and aggregates results" do
    fetch_fun = fn url, _timeout ->
      Process.sleep(60)
      {:ok, 200, String.length(url)}
    end

    started = System.monotonic_time(:millisecond)

    summary =
      ConcurrentWebScraper.fetch_many(
        ["https://a", "https://bb", "https://ccc"],
        timeout: 500,
        max_concurrency: 3,
        fetch_fun: fetch_fun
      )

    elapsed = System.monotonic_time(:millisecond) - started

    assert summary.total == 3
    assert summary.ok == 3
    assert summary.error == 0
    assert summary.timeout == 0
    assert elapsed < 140
  end

  test "handles timeouts" do
    fetch_fun = fn
      "slow", _timeout ->
        Process.sleep(80)
        {:ok, 200, 1}

      _, _timeout ->
        {:ok, 200, 2}
    end

    summary =
      ConcurrentWebScraper.fetch_many(["slow", "fast"],
        timeout: 20,
        max_concurrency: 2,
        fetch_fun: fetch_fun
      )

    assert summary.total == 2
    assert summary.ok == 1
    assert summary.timeout == 1
  end
end
