defmodule Typi.ChatChannel do
  use Typi.Web, :channel
  use Amnesia
  use Typi.Database

  def join("chats:" <> chat_id, _payload, socket) do
    if authorized?(chat_id, socket.assigns.current_user) do
      case Repo.get(Typi.Chat, chat_id) do
        nil ->
          {:error, %{reason: "unauthorized"}}
        chat ->
          {:ok, assign(socket, :current_chat, chat)}
      end
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  def handle_in("message", %{"client_id" => client_id} = payload, socket) do
    changeset = Typi.Message.changeset(%Typi.Message{}, payload)
    if changeset.valid? do
      message =
        changeset
        |> Ecto.Changeset.apply_changes
        |> Typi.Message.to_amnesia_message
        |> Map.merge(%{
          chat_id: socket.assigns.current_chat.id,
          user_id: socket.assigns.current_user.id,
          status: "sending"
        })
        |> insert_message(socket)

      broadcast_from socket, "message", Map.from_struct(message)
      {:reply, {:ok, %{id: message.id, client_id: client_id, status: message.status}}, socket}
    else
      {:reply, {:error, %{errors: changeset}}, socket}
    end
  end

  def handle_in("status", %{"id" => message_id, "status" => "received"}, socket) do
    # update status
    statuses = update_status_and_get_statuses(message_id, "received", socket)
    broadcast_if_status_changed(statuses, message_id, "received")
    {:noreply, socket}
  end

  def handle_in("status", %{"id" => message_id, "status" => "read"}, socket) do
    # update status
    statuses = update_status_and_get_statuses(message_id, "read", socket)
    broadcast_if_status_changed(statuses, message_id, "read")
    {:noreply, socket}
  end

  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
  def handle_in("ping", payload, socket) do
    {:reply, {:ok, payload}, socket}
  end

  # It is also common to receive messages from the client and
  # broadcast to everyone in the current topic (chat:lobby).
  def handle_in("shout", payload, socket) do
    broadcast socket, "shout", payload
    {:noreply, socket}
  end

  defp broadcast_if_status_changed(statuses, message_id, status) do
    if change_message_status?(statuses, false) do
      message = Amnesia.transaction do
        Message.read(message_id)
        |> Map.put(:status, status)
        |> Message.write
      end
      Typi.Endpoint.broadcast "users:#{message.user_id}", "message:status", Map.take(message, [:id, :status])
    end
  end

  defp update_status_and_get_statuses(m_id, status, socket) do
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

  defp change_message_status?([], accumulator) do
    accumulator
  end

  defp change_message_status?([h | t], accumulator) do
    if accumulator do
      accumulator
    else
      change_message_status?(t, h.status == "sending")
    end
  end

  defp insert_message(message, socket) do
    chat = Repo.preload(socket.assigns.current_chat, :users)
    Amnesia.transaction do
      message = message |> Message.write
      for user <- chat.users, (fn user -> user.id != socket.assigns.current_user.id end).(user) do
        %Status{message_id: message.id, recipient_id: user.id, status: "sending"}
        |> Status.write
      end
      message
    end
  end

  # Add authorization logic here as required.
  defp authorized?(chat_id, user) do
    case Repo.get_by(Typi.ChatUser, %{chat_id: chat_id, user_id: user.id}) do
      nil -> false
      _ -> true
    end
  end
end
