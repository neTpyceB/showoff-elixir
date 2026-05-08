defmodule TaskCli.Store do
  @moduledoc false

  @default_file ".task_cli_todos"

  @spec default_path() :: String.t()
  def default_path do
    Path.join(File.cwd!(), @default_file)
  end

  @spec load(String.t()) :: {:ok, [map()]} | {:error, atom()}
  def load(path) do
    case File.read(path) do
      {:ok, bin} ->
        decode(bin)

      {:error, :enoent} ->
        {:ok, []}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @spec save(String.t(), [map()]) :: :ok | {:error, atom()}
  def save(path, tasks) do
    path
    |> Path.dirname()
    |> File.mkdir_p()

    File.write(path, :erlang.term_to_binary(tasks))
  end

  defp decode(bin) do
    case :erlang.binary_to_term(bin, [:safe]) do
      tasks when is_list(tasks) -> {:ok, tasks}
      _ -> {:error, :invalid_data}
    end
  rescue
    ArgumentError -> {:error, :invalid_data}
  end
end
