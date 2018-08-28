defmodule ChatWeb.RoomChannel do
  use ChatWeb, :channel

  require Logger

  def join("rooms:lobby", payload, socket) do
    if authorized?(payload) do
      Process.flag(:trap_exit, true)
      :timer.send_interval(15000, :ping)
      send(self(), {:after_join, payload})
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  def handle_info({:after_join, msg}, socket) do
    broadcast!(socket, "user:entered", %{user: msg["user"]})
    push(socket, "join", %{status: "connected"})
    {:noreply, socket}
  end

  def handle_info(:ping, socket) do
    push(socket, "new:msg", %{user: "SYSTEM", body: "ping"})
    {:noreply, socket}
  end

  def terminate(reason, _socket) do
    Logger.debug ">leave #{inspect reason}"
    :ok
  end


  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
  def handle_in("ping", payload, socket) do
    {:reply, {:ok, payload}, socket}
  end

  # It is also common to receive messages from the client and
  # broadcast to everyone in the current topic (room:lobby).
  def handle_in("shout", payload, socket) do
    broadcast socket, "shout", payload
    {:noreply, socket}
  end

  def handle_in("new:msg", msg, socket) do
    broadcast!(socket, "new:msg", %{user: msg["user"], body: msg["body"]})
    {:reply, {:ok, %{msg: msg["body"]}}, assign(socket, :user, msg["user"])}
  end

  # Add authorization logic here as required.
  defp authorized?(_payload) do
    true
  end
end
