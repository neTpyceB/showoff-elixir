defmodule ConcurrentWebScraperCLITest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureIO

  test "parses cli args" do
    assert {:ok, parsed} =
             ConcurrentWebScraper.CLI.parse([
               "--timeout",
               "4000",
               "--max-concurrency",
               "3",
               "https://a"
             ])

    assert parsed.timeout == 4000
    assert parsed.max_concurrency == 3
    assert parsed.urls == ["https://a"]
  end

  test "runs and prints aggregated results" do
    output =
      capture_io(fn ->
        ConcurrentWebScraper.CLI.run(["--timeout", "100", "https://a", "https://b"], fn url,
                                                                                        _timeout ->
          {:ok, 200, String.length(url)}
        end)
      end)

    assert output =~ "Total: 2 | OK: 2 | Error: 0 | Timeout: 0"
    assert output =~ "OK      https://a"
    assert output =~ "OK      https://b"
  end

  test "shows error for missing urls" do
    output = capture_io(fn -> ConcurrentWebScraper.CLI.run([], fn _url, _timeout -> :ok end) end)
    assert output =~ "Provide at least one URL"
  end
end
