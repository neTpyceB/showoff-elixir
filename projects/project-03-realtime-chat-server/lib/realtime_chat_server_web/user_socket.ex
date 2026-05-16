defmodule RealtimeChatServerWeb.UserSocket do
  use Phoenix.Socket

  channel "room:*", RealtimeChatServerWeb.RoomChannel

  @impl true
  def connect(params, socket, _connect_info) do
    {:ok, assign(socket, :user_name, normalize_name(params["name"]))}
  end

  @impl true
  def id(_socket), do: nil

  defp normalize_name(nil), do: guest_name()

  defp normalize_name(name) do
    cleaned = name |> String.trim() |> String.slice(0, 24)

    if cleaned == "" do
      guest_name()
    else
      cleaned
    end
  end

  defp guest_name do
    "guest-" <> Integer.to_string(System.unique_integer([:positive]))
  end
end
