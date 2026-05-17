defmodule EventDrivenSaasBackendTest do
  use ExUnit.Case, async: false

  alias EventDrivenSaasBackend, as: Backend

  setup do
    Backend.reset()
    :ok
  end

  test "organizations and RBAC lifecycle" do
    assert :ok = Backend.create_organization("org-1", "owner-1")

    assert {:ok, true} = Backend.authorize("org-1", "owner-1", :manage)
    assert :ok = Backend.add_member("org-1", "owner-1", "user-1", :viewer)

    assert {:ok, false} = Backend.authorize("org-1", "user-1", :publish)
    assert :ok = Backend.set_role("org-1", "owner-1", "user-1", :member)
    assert {:ok, true} = Backend.authorize("org-1", "user-1", :publish)
  end

  test "RBAC blocks unauthorized management operations" do
    assert :ok = Backend.create_organization("org-1", "owner-1")
    assert :ok = Backend.add_member("org-1", "owner-1", "user-1", :viewer)

    assert {:error, :unauthorized} = Backend.add_member("org-1", "user-1", "user-2", :member)
  end

  test "event streams and event storage" do
    assert :ok = Backend.create_organization("org-1", "owner-1")
    assert :ok = Backend.add_member("org-1", "owner-1", "user-1", :member)
    assert :ok = Backend.subscribe_events("org-1")

    assert {:ok, event} = Backend.publish_event("org-1", "user-1", "invoice.created", %{id: 10})
    assert_receive {:event_stream, "org-1", received_event}, 1_000
    assert received_event.id == event.id

    assert {:ok, [stored_event]} = Backend.list_events("org-1", "owner-1")
    assert stored_event.type == "invoice.created"
    assert stored_event.payload == %{id: 10}
  end

  test "audit logs track successful and denied actions" do
    assert :ok = Backend.create_organization("org-1", "owner-1")
    assert :ok = Backend.add_member("org-1", "owner-1", "user-1", :viewer)

    assert {:error, :unauthorized} =
             Backend.publish_event("org-1", "user-1", "report.generated", %{})

    assert :ok = Backend.set_role("org-1", "owner-1", "user-1", :member)
    assert {:ok, _event} = Backend.publish_event("org-1", "user-1", "report.generated", %{})

    assert {:ok, logs} = Backend.list_audit_logs("org-1", "owner-1")
    assert Enum.any?(logs, &(&1.action == :event_published and &1.status == :denied))
    assert Enum.any?(logs, &(&1.action == :event_published and &1.status == :success))
  end
end
