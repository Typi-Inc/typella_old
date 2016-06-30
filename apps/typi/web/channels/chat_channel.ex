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

  def handle_in("typing", %{"status" => status}, socket) do
    # status is one of ["typing", "not typing"]
    chat = Repo.preload(socket.assigns.current_chat, :users)
    broadcast_typing(chat, status, socket)
    {:noreply, socket}
  end
  def handle_in("fm", payload, socket) do
    chat = socket.assigns.current_chat
    changeset=Typi.Message.changeset(%Typi.Message{}, payload)
    if changeset.valid? do
      message=
        changeset
        |>Ecto.Changeset.apply_changes
        |>Typi.Message.to_amnesia_message
        |> Map.merge(%{
          chat_id: socket.assigns.current_chat.id,
          user_id: socket.assigns.current_user.id,
          future_handled: false,
          status: "sending",
        })
        |> insert_message(socket, chat)
      response =
        message
        |> Map.take([:id, :created_at, :status])
        |> to_camel_case
        {:reply, {:ok, response}, socket}
    else
      {:reply, {:error, %{errors: changeset}}, socket}
    end
  end

  def handle_in("message", payload, socket) do
    IO.inspect payload
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
          future_handled: true,
          status: "sending"
        })
        |> insert_message(socket, chat)

      broadcast_from socket, "message", message |> Map.from_struct |> to_camel_case
      broadcast_typing(chat, "not typing", socket)
      users_not_in_chat = get_users_not_in_chat(chat)
      for user <- users_not_in_chat do
        Typi.Endpoint.broadcast "users:#{user.id}", "message", to_camel_case(message)
        send_push_notifications(users_not_in_chat, message)
      end
      response =
        message
        |> Map.take([:id, :created_at, :status])
        |> to_camel_case
      {:reply, {:ok, response}, socket}
    else
      {:reply, {:error, %{errors: changeset}}, socket}
    end
  end

  defp broadcast_typing(chat, status, socket) do
    for user <- chat.users, (fn user -> user.id != socket.assigns.current_user.id end).(user) do
      IO.puts "users:#{user.id}"
      Typi.Endpoint.broadcast "users:#{user.id}", "typing", %{
        chat_id: chat.id,
        user_id: socket.assigns.current_user.id,
        status: status
      } |> to_camel_case
    end
  end
  def handle_out("message", message, socket) do
    push socket, "message", message |> Map.from_struct |> to_camel_case
    {:noreply, socket}
  end

  defp to_camel_case(message) do
    map = if Map.has_key?(message, :__struct__) do
      message
        |> Map.from_struct
      else
        message
      end

    to_camel_case(map, Map.keys(map), %{})
  end

  defp to_camel_case(_map, [], json) do
    json
  end

  defp to_camel_case(map, [key | t], json) do
    new_key = key
      |> to_string
      |> string_to_camel_case

    to_camel_case(map, t, Map.put(json, new_key, map[key]))
  end

  defp string_to_camel_case(string) do
    Regex.replace(~r/_(.)/, string, fn _, group -> String.upcase(group) end)
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
