defmodule TaskCliCLITest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  setup do
    path =
      Path.join(
        System.tmp_dir!(),
        "task_cli_test_#{System.unique_integer([:positive])}.db"
      )

    System.put_env("TASK_CLI_STORE", path)

    on_exit(fn ->
      System.delete_env("TASK_CLI_STORE")
      File.rm(path)
    end)

    {:ok, path: path}
  end

  test "parses supported commands" do
    assert TaskCli.CLI.parse(["list"]) == {:ok, :list}
    assert TaskCli.CLI.parse(["add", "buy", "milk"]) == {:ok, {:add, "buy milk"}}
    assert TaskCli.CLI.parse(["done", "3"]) == {:ok, {:done, 3}}
    assert TaskCli.CLI.parse(["delete", "4"]) == {:ok, {:delete, 4}}

    assert TaskCli.CLI.parse(["add"]) == {:error, :missing_text}
    assert TaskCli.CLI.parse(["done", "x"]) == {:error, :invalid_id}
    assert TaskCli.CLI.parse(["unknown"]) == {:error, :invalid_command}
  end

  test "runs full todo workflow through cli" do
    assert capture_io(fn -> TaskCli.CLI.main(["add", "learn", "elixir"]) end) ==
             "Added todo #1.\n"

    assert capture_io(fn -> TaskCli.CLI.main(["add", "write", "tests"]) end) ==
             "Added todo #2.\n"

    assert capture_io(fn -> TaskCli.CLI.main(["done", "1"]) end) == "Completed todo #1.\n"

    assert capture_io(fn -> TaskCli.CLI.main(["list"]) end) ==
             "[x] 1. learn elixir\n[ ] 2. write tests\n"

    assert capture_io(fn -> TaskCli.CLI.main(["delete", "2"]) end) == "Deleted todo #2.\n"

    assert capture_io(fn -> TaskCli.CLI.main(["list"]) end) == "[x] 1. learn elixir\n"
  end
end
