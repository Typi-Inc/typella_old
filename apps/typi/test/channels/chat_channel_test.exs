defmodule Typi.ChatChannelTest do
  # TODO async: true does not work
  use Typi.ChannelCase

  setup do
    user = insert_user
    chat = insert_chat(%Typi.Chat{
      users: [user]
    })
    {:ok, token, _full_claims} = Guardian.encode_and_sign(user, :token)
    {:ok, socket} = connect(Typi.UserSocket, %{"token" => token})
    {:ok, socket: socket, user: user, chat: chat}
  end

  test "join replies with messages, where status is delivery", %{socket: socket, user: user, chat: chat} do
  end

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
    ref = push socket, "message", %{body: "the body", client_id: 1, created_at: "2015-04-27 10:08:42"}
    assert_reply ref, :ok, %{client_id: 1, status: "received"}
    assert Repo.get_by(Typi.Message, %{client_id: 1, body: "the body", status: "received"})
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
