defmodule Typi.UserChannel do
  use Typi.Web, :channel
  use Amnesia
  use Typi.Database

  # intercept ["message", "status", "typing"]

  def join("users:" <> user_id, _payload, socket) do
    if authorized?(user_id, socket) do
      send self(), :after_join
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  def handle_info(:after_join, socket) do
    {:ok, _} = Presence.track(socket, socket.assigns.current_user.id, %{})
    {:noreply, socket}
  end

  def handle_in("contacts", %{"contacts" => contacts}, socket) do
    
  end

  def handle_in("statuses", %{"statuses" => statuses}, socket) do
    for status <- statuses do
      handle_in("status", status, socket)
    end
    {:noreply, socket}
  end

  def handle_in("status", %{"id" => message_id, "status" => status} = payload, socket) do
    statuses = update_status_and_get_statuses(message_id, status, socket)
    broadcast_if_status_changed(statuses, message_id)
    {:noreply, socket}
  end
  #
  # def handle_out("typing", payload, socket) do
  #   push socket, "typing", payload
  #   {:noreply, socket}
  # end
  #
  # def handle_out("status", payload, socket) do
  #   IO.puts "handle out on status has been called"
  #   push socket, "status", payload
  #   {:noreply, socket}
  # end
  #
  # def handle_out("message", payload, socket) do
  #   push socket, "message", payload
  #   {:noreply, socket}
  # end

  def broadcast_if_status_changed(statuses, message_id) do
    message = Amnesia.transaction do
      Message.read(message_id)
    end
    current_status = min_status(statuses)
    if message.status != current_status do
      message = Amnesia.transaction do
        Message.read(message_id)
        |> Map.put(:status, current_status)
        |> Message.write
      end
      Typi.Endpoint.broadcast "users:#{message.user_id}", "status", Map.take(message, [:id, :status])
    end
  end

  def update_status_and_get_statuses(m_id, status, socket) do
    Amnesia.transaction do
      selection = Status.where message_id == m_id and recipient_id == socket.assigns.current_user.id, select: [id]
      [[status_id]] = selection |> Amnesia.Selection.values

      status_id
      |> Status.read
      |> Map.put(:status, status)
      |> Status.write

      Status.read_at(m_id, :message_id)
    end
  end

  defp min_status(statuses) do
    min_status(statuses, "")
  end

  defp min_status([], acc) do
    acc
  end

  defp min_status([h | t], acc) do
    cond do
      h.status == "sending" -> "sending"
      h.status == "received" or acc == "received" -> min_status(t, "received")
      true -> min_status(t, "read") # h.status == "read" && acc == "read"
    end
  end

  # Add authorization logic here as required.
  defp authorized?(user_id, socket) do
    String.to_integer(user_id) == socket.assigns.current_user.id
  end
end
