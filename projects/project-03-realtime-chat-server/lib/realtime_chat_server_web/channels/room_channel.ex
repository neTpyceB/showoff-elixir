defmodule RealtimeChatServerWeb.RoomChannel do
  use Phoenix.Channel

  alias RealtimeChatServerWeb.Presence

  @impl true
  def join("room:" <> room_name, _payload, socket) do
    socket = assign(socket, :room_name, room_name)
    send(self(), :after_join)

    {:ok, %{room: room_name, users: users_for(socket)}, socket}
  end

  @impl true
  def handle_info(:after_join, socket) do
    {:ok, _} =
      Presence.track(socket, socket.assigns.user_name, %{
        joined_at: System.system_time(:second)
      })

    push(socket, "presence_state", Presence.list(socket))
    {:noreply, socket}
  end

  @impl true
  def handle_in("new_message", %{"body" => body}, socket) do
    message = String.trim(body)

    if message == "" do
      {:reply, {:error, %{reason: "empty_message"}}, socket}
    else
      broadcast!(socket, "new_message", %{
        room: socket.assigns.room_name,
        user: socket.assigns.user_name,
        body: message,
        sent_at: DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601()
      })

      {:reply, :ok, socket}
    end
  end

  defp users_for(socket) do
    socket
    |> Presence.list()
    |> Map.keys()
    |> Enum.sort()
  end
end
