defmodule ConcurrentWebScraper.MixProject do
  use Mix.Project

  def project do
    [
      app: :concurrent_web_scraper,
      version: "0.1.0",
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      escript: [main_module: ConcurrentWebScraper.CLI],
      deps: deps()
    ]
  end

  def cli do
    [preferred_envs: ["test.watch": :test]]
  end

  def application do
    [
      extra_applications: [:logger, :inets, :ssl],
      mod: {ConcurrentWebScraper.Application, []}
    ]
  end

  defp deps do
    [
      {:mix_test_watch, "~> 1.4", only: [:dev, :test], runtime: false}
    ]
  end
end
