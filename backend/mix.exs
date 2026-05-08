defmodule TaskCli.MixProject do
  use Mix.Project

  def project do
    [
      app: :task_cli,
      version: "0.1.0",
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      escript: [main_module: TaskCli.CLI],
      deps: deps()
    ]
  end

  def cli do
    [preferred_envs: ["test.watch": :test]]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {TaskCli.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:mix_test_watch, "~> 1.4", only: [:dev, :test], runtime: false}
    ]
  end
end
