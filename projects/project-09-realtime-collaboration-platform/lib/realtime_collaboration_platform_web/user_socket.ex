defmodule RealtimeCollaborationPlatformWeb.UserSocket do
  use Phoenix.Socket

  channel "doc:*", RealtimeCollaborationPlatformWeb.CollabChannel

  @impl true
  def connect(params, socket, _connect_info) do
    {:ok, assign(socket, :user_id, normalize_user(params["user_id"]))}
  end

  @impl true
  def id(_socket), do: nil

  defp normalize_user(nil), do: guest_id()

  defp normalize_user(user_id) do
    user_id = user_id |> String.trim() |> String.slice(0, 40)
    if user_id == "", do: guest_id(), else: user_id
  end

  defp guest_id do
    "guest-" <> Integer.to_string(System.unique_integer([:positive]))
  end
end
