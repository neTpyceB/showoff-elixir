defmodule RealtimeCollaborationPlatformWeb.CollabChannel do
  use Phoenix.Channel

  alias RealtimeCollaborationPlatform.DocumentState
  alias RealtimeCollaborationPlatformWeb.Presence

  @impl true
  def join("doc:" <> doc_id, _payload, socket) do
    with {:ok, _pid} <- DocumentState.start_or_get(doc_id) do
      snapshot = DocumentState.snapshot(doc_id)
      socket = assign(socket, :doc_id, doc_id)
      send(self(), :after_join)
      {:ok, %{document: snapshot, users: users_for(socket)}, socket}
    end
  end

  @impl true
  def handle_info(:after_join, socket) do
    {:ok, _} =
      Presence.track(socket, socket.assigns.user_id, %{
        online_at: System.system_time(:second)
      })

    push(socket, "presence_state", Presence.list(socket))
    {:noreply, socket}
  end

  @impl true
  def handle_in("edit", %{"content" => content}, socket) when is_binary(content) do
    state = DocumentState.apply_edit(socket.assigns.doc_id, socket.assigns.user_id, content)

    broadcast_from!(socket, "document_updated", %{
      doc_id: socket.assigns.doc_id,
      content: state.content,
      version: state.version,
      updated_by: state.updated_by,
      updated_at: state.updated_at
    })

    {:reply, {:ok, %{document: state}}, socket}
  end

  def handle_in("sync", _payload, socket) do
    {:reply, {:ok, %{document: DocumentState.snapshot(socket.assigns.doc_id)}}, socket}
  end

  defp users_for(socket) do
    socket
    |> Presence.list()
    |> Map.keys()
    |> Enum.sort()
  end
end
