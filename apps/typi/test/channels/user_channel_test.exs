defmodule Typi.UserChannelTest do
  use Typi.ChannelCase

  setup do
    user = insert_user
    {:ok, token, _full_claims} = Guardian.encode_and_sign(user, :token)
    {:ok, socket} = connect(Typi.UserSocket, %{"token" => token})
    {:ok, _, socket} = subscribe_and_join(socket, "users:#{user.id}", %{})
    {:ok, socket: socket, user: user}
  end

  # test "When message is received by a recipient, recipient sends the status `received`, and if all statuses are `received` or `read`, it changes the status of the message and pushes it to owner via broadcast or APN", %{socket: socket, users: [john, mike, sam, sara], chat: chat} do
  #   # connect to `users:...` channel in order to see the status being pushed via `message:status`
  #   {:ok, _, _user_socket} = subscribe_and_join(socket, "users:#{john.id}", %{})
  #
  #   # send message to chat channel from john
  #   send_message(socket, chat, @message_attrs)
  #
  #   # get last message being stored
  #   message = get_message()
  #
  #   # send `received` status from mike
  #   send_message_status(mike, chat, message, "received")
  #   statuses = get_message_statuses(message.id)
  #   assert_statuses([{mike.id, "received"}, {sam.id, "sending"}, {sara.id, "sending"}], statuses)
  #
  #   # send `received` status from sam
  #   send_message_status(sam, chat, message, "read")
  #   statuses = get_message_statuses(message.id)
  #   assert_statuses([{mike.id, "received"}, {sam.id, "read"}, {sara.id, "sending"}], statuses)
  #
  #   # send `received` status from sara
  #   send_message_status(sara, chat, message, "received")
  #   statuses = get_message_statuses(message.id)
  #   assert_statuses([{mike.id, "received"}, {sam.id, "read"}, {sara.id, "received"}], statuses)
  #
  #   # chek that message's status has been changed
  #   message = get_message(message.id)
  #   assert %Message{status: "received"} = message
  #
  #   # assert that the owner of the message has been notified about status change
  #   message_id = message.id
  #   assert_push "message:status", %{id: ^message_id, status: "received"}
  # end
  #
  # test "when message is read, recipient sends the status `read`, which is pushed at owner via broadcast or APN", %{socket: socket, users: [john, mike, sam, sara], chat: chat} do
  #   # connect to users:... channel in order to see the status being pushed via `message:status`
  #   {:ok, _, _user_socket} = subscribe_and_join(socket, "users:#{john.id}", %{})
  #
  #   # send message to chat channel from john
  #   send_message(socket, chat, @message_attrs)
  #
  #   # get last message being stored
  #   message = get_message()
  #
  #   # send `read` status from mike
  #   send_message_status(mike, chat, message, "read")
  #   statuses = get_message_statuses(message.id)
  #   assert_statuses([{mike.id, "read"}, {sam.id, "sending"}, {sara.id, "sending"}], statuses)
  #
  #   # send `read` status from sam
  #   send_message_status(sam, chat, message, "read")
  #   statuses = get_message_statuses(message.id)
  #   assert_statuses([{mike.id, "read"}, {sam.id, "read"}, {sara.id, "sending"}], statuses)
  #
  #   # send `read` status from sara
  #   send_message_status(sara, chat, message, "read")
  #   statuses = get_message_statuses(message.id)
  #   assert_statuses([{mike.id, "read"}, {sam.id, "read"}, {sara.id, "read"}], statuses)
  #
  #   # chek that message's status has been changed
  #   message = get_message(message.id)
  #   assert %Message{status: "read"} = message
  #
  #   # assert that the owner of the message has been notified about status change
  #   message_id = message.id
  #   assert_push "message:status", %{id: ^message_id, status: "read"}
  # end
  #
  # test "recipient sends the status 'seen' of the last message and all messages in the chat are marked as seen" do
  #   # TODO
  #   refute true
  # end

  # test "ping replies with status ok", %{socket: socket} do
  #   ref = push socket, "ping", %{"hello" => "there"}
  #   assert_reply ref, :ok, %{"hello" => "there"}
  # end
  #
  # test "shout broadcasts to user:lobby", %{socket: socket} do
  #   push socket, "shout", %{"hello" => "all"}
  #   assert_broadcast "shout", %{"hello" => "all"}
  # end
  #
  # test "broadcasts are pushed to the client", %{socket: socket} do
  #   broadcast_from! socket, "broadcast", %{"some" => "data"}
  #   assert_push "broadcast", %{"some" => "data"}
  # end
end
