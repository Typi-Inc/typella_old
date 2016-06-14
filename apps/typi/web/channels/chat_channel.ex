defmodule Typi.ChatChannel do
  use Typi.Web, :channel
  use Amnesia
  use Typi.Database
  require Logger

  def join("chats:" <> chat_id, _payload, socket) do
    if authorized?(chat_id, socket.assigns.current_user) do
      case Repo.get(Typi.Chat, chat_id) do
        nil ->
          {:error, %{reason: "unauthorized"}}
        chat ->
          send self, :after_join
          {:ok, assign(socket, :current_chat, chat)}
      end
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  def handle_info(:after_join, socket) do
    {:ok, _} = Presence.track(socket, socket.assigns.current_user.id, %{
      chat_id: socket.assigns.current_chat.id
    })
    {:noreply, socket}
  end

  def handle_in("message", %{"client_id" => client_id} = payload, socket) do
    chat = Repo.preload(socket.assigns.current_chat, :users)
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
        |> insert_message(socket, chat)

      broadcast_from socket, "message", Map.from_struct(message)
      users_not_in_chat = get_users_not_in_chat(chat)
      for user <- users_not_in_chat do
        Typi.Endpoint.broadcast "users:#{user.id}", "message", Map.from_struct(message)
        send_push_notifications(users_not_in_chat, message)
      end
      {:reply, {:ok, %{id: message.id, client_id: client_id, status: message.status}}, socket}
    else
      {:reply, {:error, %{errors: changeset}}, socket}
    end
  end

  def handle_in("status", %{"id" => message_id, "status" => status}, socket) do
    # update status
    statuses = update_status_and_get_statuses(message_id, status, socket)
    broadcast_if_status_changed(statuses, message_id)
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

  defp send_push_notifications(users, message) do
    # for user <- users do
    #   message = APNS.Message.new
    #   message = message
    #   |> Map.put(:token, "0000000000000000000000000000000000000000000000000000000000000000")
    #   |> Map.put(:alert, message)
    #   |> Map.put(:badge, 42)
    #   |> Map.put(:extra, %{
    #     "var1" => "val1",
    #     "var2" => "val2"
    #   })
    #   APNS.push :app1_dev_pool, message
    # end
  end

  defp get_users_not_in_chat(chat) do
    presences = Presence.list("chats:#{chat.id}")
    difference(chat.users, presences, [])
  end

  defp difference([], _presences, acc) do
    acc
  end

  defp difference([user | t], presences, acc) do
    if presences[to_string(user.id)] do
      difference(t, presences, acc)
    else
      difference(t, presences, acc ++ [user])
    end
  end

  defp broadcast_if_status_changed(statuses, message_id) do
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

  defp insert_message(message, socket, chat) do
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
