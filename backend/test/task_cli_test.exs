defmodule TaskCliTest do
  use ExUnit.Case, async: true

  test "adds todos with incremental id" do
    {first, tasks} = TaskCli.add([], "learn elixir")
    {second, _tasks} = TaskCli.add(tasks, "ship cli")

    assert first == %{id: 1, text: "learn elixir", done: false}
    assert second == %{id: 2, text: "ship cli", done: false}
  end

  test "marks todo as done" do
    tasks = [
      %{id: 1, text: "a", done: false},
      %{id: 2, text: "b", done: false}
    ]

    assert {:ok, updated} = TaskCli.mark_done(tasks, 2)
    assert Enum.at(updated, 1).done
    assert {:error, :not_found} = TaskCli.mark_done(tasks, 9)
  end

  test "deletes todo by id" do
    tasks = [
      %{id: 1, text: "a", done: false},
      %{id: 2, text: "b", done: false}
    ]

    assert {:ok, [%{id: 2}]} = TaskCli.delete(tasks, 1)
    assert {:error, :not_found} = TaskCli.delete(tasks, 9)
  end

  test "renders empty and non-empty lists" do
    assert TaskCli.render([]) == "No todos yet."

    assert TaskCli.render([
             %{id: 1, text: "learn", done: false},
             %{id: 2, text: "ship", done: true}
           ]) == "[ ] 1. learn\n[x] 2. ship"
  end
end
