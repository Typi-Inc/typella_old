defmodule Typi.ChatChannel do
  use Typi.Web, :channel
  alias Typi.Message

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
    changeset = Message.changeset(%Message{}, payload)
    if changeset.valid? do
      changeset
      |> Ecto.Changeset.apply_changes
      |> Map.merge(%{
        sender: socket.assigns.current_user,
        chat: socket.assigns.current_chat,
        status: "received"
      })
      |> Repo.insert
      |> case do
        {:ok, message} ->
          {:reply, {:ok, %{client_id: client_id, status: message.status}}, socket}
        {:error, changeset} ->
          {:reply, {:error, %{errors: changeset}}, socket}
      end
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
