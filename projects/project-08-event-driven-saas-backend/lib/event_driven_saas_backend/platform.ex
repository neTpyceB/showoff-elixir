defmodule EventDrivenSaasBackend.Platform do
  @moduledoc false
  use GenServer

  @roles [:owner, :admin, :member, :viewer]
  @permissions %{
    owner: [:manage, :publish, :read],
    admin: [:manage, :publish, :read],
    member: [:publish, :read],
    viewer: [:read]
  }

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def create_organization(org_id, owner_id),
    do: GenServer.call(__MODULE__, {:create_organization, org_id, owner_id})

  def add_member(org_id, actor_id, user_id, role),
    do: GenServer.call(__MODULE__, {:add_member, org_id, actor_id, user_id, role})

  def set_role(org_id, actor_id, user_id, role),
    do: GenServer.call(__MODULE__, {:set_role, org_id, actor_id, user_id, role})

  def authorize(org_id, user_id, permission),
    do: GenServer.call(__MODULE__, {:authorize, org_id, user_id, permission})

  def publish_event(org_id, actor_id, type, payload),
    do: GenServer.call(__MODULE__, {:publish_event, org_id, actor_id, type, payload})

  def ensure_organization(org_id), do: GenServer.call(__MODULE__, {:ensure_organization, org_id})

  def list_events(org_id, actor_id),
    do: GenServer.call(__MODULE__, {:list_events, org_id, actor_id})

  def list_audit_logs(org_id, actor_id),
    do: GenServer.call(__MODULE__, {:list_audit_logs, org_id, actor_id})

  def reset, do: GenServer.call(__MODULE__, :reset)

  @impl true
  def init(_opts) do
    {:ok, %{organizations: %{}, next_event_id: 1, next_audit_id: 1}}
  end

  @impl true
  def handle_call({:create_organization, org_id, owner_id}, _from, state) do
    if Map.has_key?(state.organizations, org_id) do
      {:reply, {:error, :organization_exists}, state}
    else
      org = %{id: org_id, members: %{owner_id => :owner}, events: [], audits: []}
      state = put_in(state.organizations[org_id], org)

      {audit, state} =
        build_audit(state, org_id, :organization_created, owner_id, :success, %{
          owner_id: owner_id
        })

      state = append_audit(state, org_id, audit)
      {:reply, :ok, state}
    end
  end

  def handle_call({:add_member, org_id, actor_id, user_id, role}, _from, state) do
    with :ok <- validate_role(role),
         {:ok, org} <- fetch_org(state, org_id),
         :ok <- ensure_permission(org, actor_id, :manage),
         false <- Map.has_key?(org.members, user_id) do
      org = put_in(org.members[user_id], role)
      state = put_in(state.organizations[org_id], org)

      {audit, state} =
        build_audit(state, org_id, :member_added, actor_id, :success, %{
          user_id: user_id,
          role: role
        })

      state = append_audit(state, org_id, audit)
      {:reply, :ok, state}
    else
      true ->
        {:reply, {:error, :member_exists}, state}

      {:error, :unauthorized} ->
        {audit, state} =
          build_audit(state, org_id, :member_added, actor_id, :denied, %{
            user_id: user_id,
            role: role
          })

        {:reply, {:error, :unauthorized}, append_audit(state, org_id, audit)}

      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  def handle_call({:set_role, org_id, actor_id, user_id, role}, _from, state) do
    with :ok <- validate_role(role),
         {:ok, org} <- fetch_org(state, org_id),
         :ok <- ensure_permission(org, actor_id, :manage),
         true <- Map.has_key?(org.members, user_id) do
      org = put_in(org.members[user_id], role)
      state = put_in(state.organizations[org_id], org)

      {audit, state} =
        build_audit(state, org_id, :role_updated, actor_id, :success, %{
          user_id: user_id,
          role: role
        })

      state = append_audit(state, org_id, audit)
      {:reply, :ok, state}
    else
      false ->
        {:reply, {:error, :member_not_found}, state}

      {:error, :unauthorized} ->
        {audit, state} =
          build_audit(state, org_id, :role_updated, actor_id, :denied, %{
            user_id: user_id,
            role: role
          })

        {:reply, {:error, :unauthorized}, append_audit(state, org_id, audit)}

      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  def handle_call({:authorize, org_id, user_id, permission}, _from, state) do
    reply =
      case fetch_org(state, org_id) do
        {:ok, org} -> {:ok, allowed?(org, user_id, permission)}
        {:error, reason} -> {:error, reason}
      end

    {:reply, reply, state}
  end

  def handle_call({:publish_event, org_id, actor_id, type, payload}, _from, state) do
    with {:ok, org} <- fetch_org(state, org_id),
         :ok <- ensure_permission(org, actor_id, :publish) do
      event = %{
        id: state.next_event_id,
        org_id: org_id,
        type: type,
        payload: payload,
        actor_id: actor_id,
        at: now_iso()
      }

      state = put_in(state.organizations[org_id].events, [event | org.events])
      state = %{state | next_event_id: state.next_event_id + 1}
      broadcast_event(org_id, event)

      {audit, state} =
        build_audit(state, org_id, :event_published, actor_id, :success, %{
          type: type,
          event_id: event.id
        })

      state = append_audit(state, org_id, audit)
      {:reply, {:ok, event}, state}
    else
      {:error, :unauthorized} ->
        {audit, state} =
          build_audit(state, org_id, :event_published, actor_id, :denied, %{type: type})

        {:reply, {:error, :unauthorized}, append_audit(state, org_id, audit)}

      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  def handle_call({:ensure_organization, org_id}, _from, state) do
    reply =
      case fetch_org(state, org_id) do
        {:ok, _org} -> :ok
        {:error, reason} -> {:error, reason}
      end

    {:reply, reply, state}
  end

  def handle_call({:list_events, org_id, actor_id}, _from, state) do
    with {:ok, org} <- fetch_org(state, org_id),
         :ok <- ensure_permission(org, actor_id, :read) do
      {:reply, {:ok, Enum.reverse(org.events)}, state}
    else
      {:error, reason} -> {:reply, {:error, reason}, state}
    end
  end

  def handle_call({:list_audit_logs, org_id, actor_id}, _from, state) do
    with {:ok, org} <- fetch_org(state, org_id),
         :ok <- ensure_permission(org, actor_id, :read) do
      {:reply, {:ok, Enum.reverse(org.audits)}, state}
    else
      {:error, reason} -> {:reply, {:error, reason}, state}
    end
  end

  def handle_call(:reset, _from, state) do
    {:reply, :ok, %{state | organizations: %{}, next_event_id: 1, next_audit_id: 1}}
  end

  defp broadcast_event(org_id, event) do
    Registry.dispatch(EventDrivenSaasBackend.EventRegistry, org_id, fn entries ->
      Enum.each(entries, fn {pid, _value} ->
        send(pid, {:event_stream, org_id, event})
      end)
    end)
  end

  defp fetch_org(state, org_id) do
    case Map.fetch(state.organizations, org_id) do
      {:ok, org} -> {:ok, org}
      :error -> {:error, :organization_not_found}
    end
  end

  defp validate_role(role) do
    if role in @roles do
      :ok
    else
      {:error, :invalid_role}
    end
  end

  defp ensure_permission(org, user_id, permission) do
    if allowed?(org, user_id, permission), do: :ok, else: {:error, :unauthorized}
  end

  defp allowed?(org, user_id, permission) do
    case Map.get(org.members, user_id) do
      nil -> false
      role -> permission in Map.fetch!(@permissions, role)
    end
  end

  defp append_audit(state, org_id, audit) do
    update_in(state.organizations[org_id].audits, &[audit | &1])
  end

  defp build_audit(state, org_id, action, actor_id, status, details) do
    audit = %{
      id: state.next_audit_id,
      org_id: org_id,
      action: action,
      actor_id: actor_id,
      status: status,
      details: details,
      at: now_iso()
    }

    {audit, %{state | next_audit_id: state.next_audit_id + 1}}
  end

  defp now_iso do
    DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601()
  end
end
