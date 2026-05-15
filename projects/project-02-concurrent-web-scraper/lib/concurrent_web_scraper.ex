defmodule ConcurrentWebScraper do
  @moduledoc false

  @default_timeout 3_000

  @type fetch_result :: {:ok, non_neg_integer(), non_neg_integer()} | {:error, term()}
  @type url_result :: %{url: String.t(), status: :ok | :error | :timeout, details: map()}

  @spec fetch_many([String.t()], keyword()) :: %{
          total: non_neg_integer(),
          ok: non_neg_integer(),
          error: non_neg_integer(),
          timeout: non_neg_integer(),
          results: [url_result()]
        }
  def fetch_many(urls, opts \\ []) do
    timeout = Keyword.get(opts, :timeout, @default_timeout)
    max_concurrency = Keyword.get(opts, :max_concurrency, System.schedulers_online())
    fetch_fun = Keyword.get(opts, :fetch_fun, &fetch_url/2)

    results =
      urls
      |> run_tasks(timeout, max_concurrency, fetch_fun)
      |> Enum.map(&normalize_result/1)

    %{results: results}
    |> Map.merge(counts(results))
  end

  @spec fetch_url(String.t(), non_neg_integer()) :: fetch_result()
  def fetch_url(url, timeout) do
    case :httpc.request(
           :get,
           {String.to_charlist(url), []},
           [timeout: timeout],
           body_format: :binary
         ) do
      {:ok, {{_, status_code, _}, _headers, body}} -> {:ok, status_code, byte_size(body)}
      {:error, reason} -> {:error, reason}
    end
  end

  defp run_tasks(urls, timeout, max_concurrency, fetch_fun) do
    urls
    |> Enum.map(fn url ->
      task = Task.async(fn -> safe_fetch(fetch_fun, url, timeout) end)
      {url, task}
    end)
    |> Enum.chunk_every(max_concurrency)
    |> Enum.flat_map(fn chunk ->
      Enum.map(chunk, fn {url, task} ->
        {url, Task.yield(task, timeout) || Task.shutdown(task, :brutal_kill)}
      end)
    end)
  end

  defp safe_fetch(fetch_fun, url, timeout) do
    fetch_fun.(url, timeout)
  rescue
    exception -> {:error, {:exception, Exception.message(exception)}}
  catch
    kind, reason -> {:error, {kind, reason}}
  end

  defp normalize_result({url, {:ok, {:ok, status_code, body_size}}}) do
    %{url: url, status: :ok, details: %{status_code: status_code, body_size: body_size}}
  end

  defp normalize_result({url, {:ok, {:error, reason}}}) do
    %{url: url, status: :error, details: %{reason: inspect(reason)}}
  end

  defp normalize_result({url, nil}) do
    %{url: url, status: :timeout, details: %{reason: "timeout"}}
  end

  defp counts(results) do
    Enum.reduce(results, %{total: length(results), ok: 0, error: 0, timeout: 0}, fn result, acc ->
      case result.status do
        :ok -> %{acc | ok: acc.ok + 1}
        :error -> %{acc | error: acc.error + 1}
        :timeout -> %{acc | timeout: acc.timeout + 1}
      end
    end)
  end
end
