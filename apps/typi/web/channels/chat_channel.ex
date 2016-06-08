defmodule Typi.ChatChannel do
  use Typi.Web, :channel
  use Amnesia
  use Database

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

  def handle_in("status", %{"id" => m_id, "status" => "received"}, socket) do
    # update status
    statuses = Amnesia.transaction do
      selection = Status.where message_id == m_id and recipient_id == socket.assigns.current_user.id, select: [id]
      [[status_id]] = selection |> Amnesia.Selection.values

      status_id
      |> Status.read
      |> Map.put(:status, "received")
      |> Status.write

      Status.read_at(m_id, :message_id)
    end

    # check if all statuses are != sending
    if change_message_status?(statuses, false) do
      message = Amnesia.transaction do
        Message.read(m_id)
        |> Map.put(:status, "received")
        |> Message.write
      end
      # TODO Need to change it to a push to owner of the mesage
      broadcast socket, "status", Map.take(message, [:id, :status])
    end
    {:noreply, socket}
  end

  def handle_in("status", %{"id" => message_id, "status" => "read"}, socket) do

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
