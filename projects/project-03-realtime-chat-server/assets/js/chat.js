import {Socket} from "phoenix"

const chatApp = document.getElementById("chat-app")

if (chatApp) {
  const nameInput = document.getElementById("chat-name")
  const roomInput = document.getElementById("chat-room")
  const connectBtn = document.getElementById("chat-connect")
  const statusEl = document.getElementById("chat-status")
  const usersEl = document.getElementById("chat-users")
  const messagesEl = document.getElementById("chat-messages")
  const formEl = document.getElementById("chat-form")
  const inputEl = document.getElementById("chat-input")

  let socket = null
  let channel = null
  let presenceState = {}

  const appendMessage = ({user, body, sent_at}) => {
    const line = document.createElement("p")
    line.textContent = `[${sent_at}] ${user}: ${body}`
    messagesEl.appendChild(line)
    messagesEl.scrollTop = messagesEl.scrollHeight
  }

  const renderUsers = () => {
    const names = Object.keys(presenceState).sort()
    usersEl.innerHTML = ""

    names.forEach(name => {
      const li = document.createElement("li")
      li.textContent = name
      usersEl.appendChild(li)
    })
  }

  const applyPresenceDiff = diff => {
    Object.entries(diff.joins || {}).forEach(([name, meta]) => {
      presenceState[name] = meta
    })

    Object.entries(diff.leaves || {}).forEach(([name, meta]) => {
      const current = presenceState[name]

      if (!current) {
        return
      }

      const currentRefs = new Set((current.metas || []).map(item => item.phx_ref))
      const leavingRefs = new Set((meta.metas || []).map(item => item.phx_ref))
      const remainingMetas = (current.metas || []).filter(item => !leavingRefs.has(item.phx_ref))

      if (remainingMetas.length === 0 || remainingMetas.every(item => !currentRefs.has(item.phx_ref))) {
        delete presenceState[name]
      } else {
        presenceState[name] = {...current, metas: remainingMetas}
      }
    })
  }

  const disconnect = () => {
    if (channel) {
      channel.leave()
      channel = null
    }

    if (socket) {
      socket.disconnect()
      socket = null
    }

    presenceState = {}
    renderUsers()
    statusEl.textContent = "Not connected"
  }

  const connect = () => {
    disconnect()

    const room = (roomInput.value || "lobby").trim() || "lobby"
    const name = (nameInput.value || "guest").trim() || "guest"

    socket = new Socket("/socket", {params: {name}})
    socket.connect()

    channel = socket.channel(`room:${room}`)

    channel.on("new_message", appendMessage)

    channel.on("presence_state", state => {
      presenceState = state
      renderUsers()
    })

    channel.on("presence_diff", diff => {
      applyPresenceDiff(diff)
      renderUsers()
    })

    channel.join()
      .receive("ok", ({room: joinedRoom}) => {
        statusEl.textContent = `Connected to room: ${joinedRoom}`
      })
      .receive("error", () => {
        statusEl.textContent = "Failed to connect"
      })
  }

  connectBtn.addEventListener("click", connect)

  formEl.addEventListener("submit", event => {
    event.preventDefault()

    if (!channel) {
      statusEl.textContent = "Connect first"
      return
    }

    const body = inputEl.value.trim()

    if (body === "") {
      return
    }

    channel.push("new_message", {body})
    inputEl.value = ""
  })

  connect()
}
