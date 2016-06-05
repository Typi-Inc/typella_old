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
          status: "received"
        })
      Amnesia.transaction do
        message |> Message.write
      end
      {:reply, {:ok, %{client_id: client_id, status: message.status}}, socket}
    else
      {:reply, {:error, %{errors: changeset}}, socket}
    end
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

  # Add authorization logic here as required.
  defp authorized?(chat_id, user) do
    case Repo.get_by(Typi.ChatUser, %{chat_id: chat_id, user_id: user.id}) do
      nil -> false
      _ -> true
    end
  end
end
