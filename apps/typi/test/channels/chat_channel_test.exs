defmodule Typi.ChatChannelTest do
  use Typi.ChannelCase
  use Amnesia
  use Database

  setup do
    user = insert_user
    chat = insert_chat(%Typi.Chat{
      users: [user]
    })
    {:ok, token, _full_claims} = Guardian.encode_and_sign(user, :token)
    {:ok, socket} = connect(Typi.UserSocket, %{"token" => token})
    {:ok, socket: socket, user: user, chat: chat}
  end

  # test "join replies with messages, where status is delivery", %{socket: socket, user: user, chat: chat} do
  # end

  test "can only join authorized chats", %{socket: socket, user: user, chat: chat} do
    assert {:ok, _, socket} = subscribe_and_join(socket, "chats:#{chat.id}", %{})
    chat = insert_chat
    assert {:error, %{reason: "unauthorized"}} = subscribe_and_join(socket, "chats:#{chat.id}", %{})
  end

  test "chat gets assigned to socket if successfully joined", %{socket: socket, user: user, chat: chat} do
    assert {:ok, _, socket} = subscribe_and_join(socket, "chats:#{chat.id}", %{})
    assert socket.assigns.current_chat.id == chat.id
  end

  test "server receives message, stores it and replies with `received` status", %{socket: socket, user: user, chat: chat} do
    {:ok, _, socket} = subscribe_and_join(socket, "chats:#{chat.id}", %{})
    ref = push socket, "message", %{body: "the body", client_id: 1, created_at: :os.system_time(:seconds)}
    assert_reply ref, :ok, %{client_id: 1, status: "received"}

    [message] = Amnesia.transaction do
      selection = Message.where chat_id == chat.id, select: [body, client_id, chat_id, created_at, status, user_id]
      selection
      |> Amnesia.Selection.values
    end
    chat_id = chat.id
    user_id = user.id
    assert ["the body", 1, ^chat_id, _, "received", ^user_id] = message
  end

  test "after receiving message server checks the presence of " do

  end

  # test "ping replies with status ok", %{socket: socket} do
  #   IO.inspect socket
  #   ref = push socket, "ping", %{"hello" => "there"}
  #   assert_reply ref, :ok, %{"hello" => "there"}
  # end
  #
  # test "shout broadcasts to chat:lobby", %{socket: socket} do
  #   push socket, "shout", %{"hello" => "all"}
  #   assert_broadcast "shout", %{"hello" => "all"}
  # end
  #
  # test "broadcasts are pushed to the client", %{socket: socket} do
  #   broadcast_from! socket, "broadcast", %{"some" => "data"}
  #   assert_push "broadcast", %{"some" => "data"}
  # end
end
