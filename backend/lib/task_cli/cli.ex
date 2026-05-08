defmodule TaskCli.CLI do
  @moduledoc false

  alias TaskCli.Store

  @spec main([String.t()]) :: :ok
  def main(args) do
    args
    |> parse()
    |> execute()
  end

  @spec parse([String.t()]) ::
          {:ok,
           :list | :help | {:add, String.t()} | {:done, pos_integer()} | {:delete, pos_integer()}}
          | {:error, :invalid_command | :invalid_id | :missing_text}
  def parse(["list"]), do: {:ok, :list}
  def parse(["help"]), do: {:ok, :help}

  def parse(["add" | words]) do
    words
    |> Enum.join(" ")
    |> String.trim()
    |> parse_add_text()
  end

  def parse(["done", id]), do: parse_id(:done, id)
  def parse(["delete", id]), do: parse_id(:delete, id)
  def parse(_), do: {:error, :invalid_command}

  defp parse_add_text(""), do: {:error, :missing_text}
  defp parse_add_text(text), do: {:ok, {:add, text}}

  defp parse_id(action, raw_id) do
    case Integer.parse(raw_id) do
      {id, ""} when id > 0 -> {:ok, {action, id}}
      _ -> {:error, :invalid_id}
    end
  end

  defp execute({:ok, :help}) do
    IO.puts(help_text())
  end

  defp execute({:ok, command}) do
    path = storage_path()

    with {:ok, tasks} <- Store.load(path),
         {:ok, updated_tasks, output} <- run(command, tasks),
         :ok <- Store.save(path, updated_tasks) do
      IO.puts(output)
      :ok
    else
      {:ok, output} ->
        IO.puts(output)
        :ok

      {:error, :not_found} ->
        IO.puts("Todo not found.")
        :ok

      {:error, reason} ->
        IO.puts("Storage error: #{inspect(reason)}")
        :ok
    end
  end

  defp execute({:error, :invalid_command}) do
    IO.puts("Invalid command. Run `help`.")
  end

  defp execute({:error, :invalid_id}) do
    IO.puts("Invalid id. Use a positive integer.")
  end

  defp execute({:error, :missing_text}) do
    IO.puts("Missing todo text.")
  end

  defp run(:list, tasks), do: {:ok, TaskCli.render(tasks)}

  defp run({:add, text}, tasks) do
    {task, updated_tasks} = TaskCli.add(tasks, text)
    {:ok, updated_tasks, "Added todo ##{task.id}."}
  end

  defp run({:done, id}, tasks) do
    case TaskCli.mark_done(tasks, id) do
      {:ok, updated_tasks} -> {:ok, updated_tasks, "Completed todo ##{id}."}
      {:error, :not_found} -> {:error, :not_found}
    end
  end

  defp run({:delete, id}, tasks) do
    case TaskCli.delete(tasks, id) do
      {:ok, updated_tasks} -> {:ok, updated_tasks, "Deleted todo ##{id}."}
      {:error, :not_found} -> {:error, :not_found}
    end
  end

  defp storage_path do
    System.get_env("TASK_CLI_STORE", Store.default_path())
  end

  defp help_text do
    [
      "Task CLI Utility",
      "",
      "Commands:",
      "  add <text>",
      "  list",
      "  done <id>",
      "  delete <id>",
      "  help"
    ]
    |> Enum.join("\n")
  end
end
