defmodule EventDrivenSaasBackend do
  @moduledoc """
  Event-driven SaaS backend with organizations, RBAC, event streams, and audit logs.
  """

  alias EventDrivenSaasBackend.Platform

  def create_organization(org_id, owner_id),
    do: Platform.create_organization(org_id, owner_id)

  def add_member(org_id, actor_id, user_id, role),
    do: Platform.add_member(org_id, actor_id, user_id, role)

  def set_role(org_id, actor_id, user_id, role),
    do: Platform.set_role(org_id, actor_id, user_id, role)

  def authorize(org_id, user_id, permission),
    do: Platform.authorize(org_id, user_id, permission)

  def publish_event(org_id, actor_id, type, payload),
    do: Platform.publish_event(org_id, actor_id, type, payload)

  def subscribe_events(org_id) do
    with :ok <- Platform.ensure_organization(org_id),
         {:ok, _owner} <- Registry.register(EventDrivenSaasBackend.EventRegistry, org_id, []) do
      :ok
    end
  end

  def list_events(org_id, actor_id), do: Platform.list_events(org_id, actor_id)
  def list_audit_logs(org_id, actor_id), do: Platform.list_audit_logs(org_id, actor_id)
  def reset, do: Platform.reset()
end
