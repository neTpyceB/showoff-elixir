defmodule RealtimeCollaborationPlatformWeb.CollabChannelTest do
  use RealtimeCollaborationPlatformWeb.ChannelCase, async: false

  alias RealtimeCollaborationPlatformWeb.UserSocket

  test "join returns document snapshot and presence state" do
    {:ok, _, socket} =
      UserSocket
      |> socket("user-1", %{user_id: "user-1"})
      |> subscribe_and_join(RealtimeCollaborationPlatformWeb.CollabChannel, "doc:alpha", %{})

    assert socket.assigns.doc_id == "alpha"
    assert_receive %Phoenix.Socket.Message{event: "presence_state"}, 1_000
  end

  test "edit broadcasts update and sync returns latest content" do
    {:ok, _, socket_a} =
      UserSocket
      |> socket("user-1", %{user_id: "user-1"})
      |> subscribe_and_join(RealtimeCollaborationPlatformWeb.CollabChannel, "doc:alpha", %{})

    {:ok, _, socket_b} =
      UserSocket
      |> socket("user-2", %{user_id: "user-2"})
      |> subscribe_and_join(RealtimeCollaborationPlatformWeb.CollabChannel, "doc:alpha", %{})

    ref = push(socket_a, "edit", %{"content" => "Hello realtime"})
    assert_reply ref, :ok, %{document: %{content: "Hello realtime", version: 1}}

    assert_broadcast "document_updated", %{
      content: "Hello realtime",
      version: 1,
      updated_by: "user-1"
    }

    ref = push(socket_b, "sync", %{})

    assert_reply ref, :ok, %{
      document: %{content: "Hello realtime", version: 1, updated_by: "user-1"}
    }
  end

  test "distributed state is shared across channels by document id" do
    {:ok, _, socket_a} =
      UserSocket
      |> socket("editor-a", %{user_id: "editor-a"})
      |> subscribe_and_join(RealtimeCollaborationPlatformWeb.CollabChannel, "doc:shared", %{})

    {:ok, _, socket_b} =
      UserSocket
      |> socket("editor-b", %{user_id: "editor-b"})
      |> subscribe_and_join(RealtimeCollaborationPlatformWeb.CollabChannel, "doc:shared", %{})

    ref = push(socket_a, "edit", %{"content" => "v1"})
    assert_reply ref, :ok, %{document: %{version: 1}}

    ref = push(socket_b, "sync", %{})
    assert_reply ref, :ok, %{document: %{content: "v1", version: 1}}
  end
end
