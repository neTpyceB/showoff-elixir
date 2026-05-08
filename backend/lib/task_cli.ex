defmodule TaskCli do
  @moduledoc false

  @type task :: %{id: pos_integer(), text: String.t(), done: boolean()}

  @spec add([task()], String.t()) :: {task(), [task()]}
  def add(tasks, text) when is_binary(text) do
    task = %{id: next_id(tasks), text: text, done: false}
    {task, tasks ++ [task]}
  end

  @spec mark_done([task()], pos_integer()) :: {:ok, [task()]} | {:error, :not_found}
  def mark_done([], _id), do: {:error, :not_found}

  def mark_done([%{id: id} = task | rest], id) do
    {:ok, [%{task | done: true} | rest]}
  end

  def mark_done([task | rest], id) do
    case mark_done(rest, id) do
      {:ok, updated_rest} -> {:ok, [task | updated_rest]}
      {:error, :not_found} -> {:error, :not_found}
    end
  end

  @spec delete([task()], pos_integer()) :: {:ok, [task()]} | {:error, :not_found}
  def delete([], _id), do: {:error, :not_found}

  def delete([%{id: id} | rest], id), do: {:ok, rest}

  def delete([task | rest], id) do
    case delete(rest, id) do
      {:ok, updated_rest} -> {:ok, [task | updated_rest]}
      {:error, :not_found} -> {:error, :not_found}
    end
  end

  @spec render([task()]) :: String.t()
  def render([]), do: "No todos yet."

  def render(tasks) do
    tasks
    |> Enum.map_join("\n", &render_task/1)
  end

  defp render_task(%{id: id, text: text, done: done}) do
    status = if(done, do: "x", else: " ")
    "[#{status}] #{id}. #{text}"
  end

  defp next_id([]), do: 1

  defp next_id(tasks) do
    tasks
    |> Enum.map(& &1.id)
    |> Enum.max()
    |> Kernel.+(1)
  end
end
