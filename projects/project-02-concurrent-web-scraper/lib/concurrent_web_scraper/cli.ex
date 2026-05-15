defmodule ConcurrentWebScraper.CLI do
  @moduledoc false

  @spec main([String.t()]) :: :ok
  def main(args) do
    run(args, &ConcurrentWebScraper.fetch_url/2)
  end

  @spec run([String.t()], (String.t(), non_neg_integer() -> term())) :: :ok
  def run(args, fetch_fun) do
    case parse(args) do
      {:ok, %{urls: urls, timeout: timeout, max_concurrency: max_concurrency}} ->
        summary =
          ConcurrentWebScraper.fetch_many(urls,
            timeout: timeout,
            max_concurrency: max_concurrency,
            fetch_fun: fetch_fun
          )

        IO.puts(render(summary))

      {:help} ->
        IO.puts(help_text())

      {:error, message} ->
        IO.puts(message)
    end

    :ok
  end

  @spec parse([String.t()]) ::
          {:ok, %{urls: [String.t()], timeout: pos_integer(), max_concurrency: pos_integer()}}
          | {:help}
          | {:error, String.t()}
  def parse(args) do
    {opts, urls, invalid} =
      OptionParser.parse(args,
        strict: [timeout: :integer, max_concurrency: :integer, help: :boolean],
        aliases: [t: :timeout, c: :max_concurrency, h: :help]
      )

    cond do
      opts[:help] ->
        {:help}

      invalid != [] ->
        {:error, "Invalid options. Run with --help."}

      urls == [] ->
        {:error, "Provide at least one URL. Run with --help."}

      not valid_positive_integer?(opts[:timeout] || 3_000) ->
        {:error, "Timeout must be a positive integer in milliseconds."}

      not valid_positive_integer?(opts[:max_concurrency] || System.schedulers_online()) ->
        {:error, "Max concurrency must be a positive integer."}

      true ->
        {:ok,
         %{
           urls: urls,
           timeout: opts[:timeout] || 3_000,
           max_concurrency: opts[:max_concurrency] || System.schedulers_online()
         }}
    end
  end

  defp valid_positive_integer?(value), do: is_integer(value) and value > 0

  defp render(summary) do
    header =
      "Total: #{summary.total} | OK: #{summary.ok} | Error: #{summary.error} | Timeout: #{summary.timeout}"

    lines =
      Enum.map(summary.results, fn result ->
        case result.status do
          :ok ->
            "OK      #{result.url} status=#{result.details.status_code} bytes=#{result.details.body_size}"

          :error ->
            "ERROR   #{result.url} reason=#{result.details.reason}"

          :timeout ->
            "TIMEOUT #{result.url}"
        end
      end)

    Enum.join([header | lines], "\n")
  end

  defp help_text do
    [
      "Concurrent Web Scraper",
      "",
      "Usage:",
      "  ./concurrent_web_scraper [--timeout 3000] [--max-concurrency 4] <url1> <url2> ...",
      "",
      "Options:",
      "  -t, --timeout           Request timeout in milliseconds (default: 3000)",
      "  -c, --max-concurrency   Parallel workers (default: schedulers_online)",
      "  -h, --help              Show help"
    ]
    |> Enum.join("\n")
  end
end
