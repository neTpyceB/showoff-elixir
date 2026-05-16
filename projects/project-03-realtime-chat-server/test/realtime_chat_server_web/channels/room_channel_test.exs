defmodule RealtimeChatServerWeb.RoomChannelTest do
  use RealtimeChatServerWeb.ChannelCase, async: true

  alias RealtimeChatServerWeb.RoomChannel
  alias RealtimeChatServerWeb.UserSocket

  test "joins room and sends messages" do
    {:ok, _reply, socket} =
      UserSocket
      |> socket("user-1", %{user_name: "alice"})
      |> subscribe_and_join(RoomChannel, "room:lobby")

    ref = push(socket, "new_message", %{"body" => "hello"})
    assert_reply ref, :ok

    assert_broadcast "new_message", %{body: "hello", user: "alice", room: "lobby"}
  end

  test "rejects empty messages" do
    {:ok, _reply, socket} =
      UserSocket
      |> socket("user-2", %{user_name: "bob"})
      |> subscribe_and_join(RoomChannel, "room:lobby")

    ref = push(socket, "new_message", %{"body" => "   "})
    assert_reply ref, :error, %{reason: "empty_message"}
  end
end
