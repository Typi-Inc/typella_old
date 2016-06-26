defmodule Typi.UserChannel do
  use Typi.Web, :channel

  def join("users:" <> user_id, _payload, socket) do
    if authorized?(user_id, socket) do
      send self(), :after_join
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  def handle_info(:after_join, socket) do
    {:noreply, socket}
  end

  def handle_in("status", %{"id" => message_id, "status" => status} = payload, socket) do
    IO.inspect payload
    statuses = Typi.ChatChannel.update_status_and_get_statuses(message_id, status, socket)
    Typi.ChatChannel.broadcast_if_status_changed(statuses, message_id)
    {:noreply, socket}
  end

  def handle_out("message:status", payload, socket) do
    push socket, "message:status", payload
    {:noreply, socket}
  end

  def handle_out("message", payload, socket) do
    push socket, "message", payload
    {:noreply, socket}
  end

  # Add authorization logic here as required.
  defp authorized?(user_id, socket) do
    String.to_integer(user_id) == socket.assigns.current_user.id
  end
end
