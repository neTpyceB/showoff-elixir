defmodule FaultTolerantJobProcessingSystem do
  @moduledoc false

  alias FaultTolerantJobProcessingSystem.Server

  def submit(payload, opts \\ []) do
    Server.enqueue(payload, opts)
  end

  def stats do
    Server.stats()
  end

  def results do
    Server.results()
  end

  def reset do
    Server.reset()
  end
end
