defmodule RealtimeCollaborationPlatform.DocumentState do
  @moduledoc false
  use GenServer, restart: :temporary

  def start_or_get(doc_id) do
    case whereis(doc_id) do
      nil ->
        child = {__MODULE__, doc_id}

        case DynamicSupervisor.start_child(
               RealtimeCollaborationPlatform.DocumentSupervisor,
               child
             ) do
          {:ok, pid} -> {:ok, pid}
          {:error, {:already_started, pid}} -> {:ok, pid}
          other -> other
        end

      pid ->
        {:ok, pid}
    end
  end

  def snapshot(doc_id), do: GenServer.call(global_name(doc_id), :snapshot)

  def apply_edit(doc_id, user_id, content),
    do: GenServer.call(global_name(doc_id), {:apply_edit, user_id, content})

  def start_link(doc_id) do
    GenServer.start_link(__MODULE__, doc_id, name: global_name(doc_id))
  end

  @impl true
  def init(doc_id) do
    {:ok, %{doc_id: doc_id, content: "", version: 0, updated_by: nil, updated_at: nil}}
  end

  @impl true
  def handle_call(:snapshot, _from, state) do
    {:reply, state, state}
  end

  def handle_call({:apply_edit, user_id, content}, _from, state) do
    new_state = %{
      state
      | content: content,
        version: state.version + 1,
        updated_by: user_id,
        updated_at: now_iso()
    }

    {:reply, new_state, new_state}
  end

  defp whereis(doc_id) do
    case :global.whereis_name(global_key(doc_id)) do
      :undefined -> nil
      pid -> pid
    end
  end

  defp global_name(doc_id), do: {:global, global_key(doc_id)}
  defp global_key(doc_id), do: {:collab_doc, doc_id}

  defp now_iso do
    DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601()
  end
end
