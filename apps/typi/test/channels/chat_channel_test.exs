defmodule Typi.ChatChannelTest do
  use Typi.ChannelCase
  use Amnesia
  use Typi.Database

  @message_attrs  %{body: "the body", client_id: 1, created_at: :os.system_time(:seconds)}

  setup_all do
    Amnesia.Schema.create
    Amnesia.start

    on_exit fn ->
      Amnesia.stop
      Amnesia.Schema.destroy
    end
    :ok
  end

  setup do
    Typi.Database.create!
    on_exit fn ->
      Typi.Database.destroy
    end
    john = insert_user
    mike = insert_user
    sam = insert_user
    sara = insert_user
    chat = insert_chat(%Typi.Chat{
      users: [john, mike, sam, sara]
    })
    {:ok, socket} = connect_with_token(john)
    {:ok, socket: socket, users: [john, mike, sam, sara], chat: chat}
  end

  # test "join replies with messages, where status is delivery", %{socket: socket, user: user, chat: chat} do
  # end

  test "can only join authorized chats", %{socket: socket, users: _users, chat: chat} do
    assert {:ok, _, socket} = subscribe_and_join(socket, "chats:#{chat.id}", %{})
    chat = insert_chat
    assert {:error, %{reason: "unauthorized"}} = subscribe_and_join(socket, "chats:#{chat.id}", %{})
  end

  test "chat gets assigned to socket if successfully joined", %{socket: socket, users: _users, chat: chat} do
    assert {:ok, _, socket} = subscribe_and_join(socket, "chats:#{chat.id}", %{})
    assert socket.assigns.current_chat.id == chat.id
  end

  test "server receives message, stores it, creates status entries and replies with `sending` status", %{socket: socket, users: [john, mike, sam, sara], chat: chat} do
    {:ok, _, socket} = subscribe_and_join(socket, "chats:#{chat.id}", %{})
    ref = push socket, "message", @message_attrs
    assert_reply ref, :ok, %{id: _, client_id: 1, status: "sending"}

    message = get_message()
    chat_id = chat.id
    john_id = john.id
    assert %Message{body: "the body", client_id: 1, chat_id: ^chat_id, status: "sending", user_id: ^john_id} = message

    statuses = get_message_statuses(message.id)
    assert length(statuses) == 3
    assert_statuses([{mike.id, "sending"}, {sam.id, "sending"}, {sara.id, "sending"}], statuses)
  end

  test "after message is received by the server, it broadcasts to all recipients currently in chat", %{socket: socket, users: [john, _mike, _sam, _sara], chat: chat} do
    {:ok, _, socket} = subscribe_and_join(socket, "chats:#{chat.id}", %{})
    _ref = push socket, "message", @message_attrs
    john_id = john.id
    assert_broadcast "message", %{id: _, body: "the body", created_at: _, user_id: ^john_id, status: "sending"}
  end

  test "after message is received by the server it broadcasts to those who are not in the chat but are online", %{socket: socket, users: [john, mike, sam, sara], chat: chat} do
    {:ok, _, socket} = subscribe_and_join(socket, "chats:#{chat.id}")
    Typi.Endpoint.subscribe "users:#{mike.id}"
    push socket, "message", @message_attrs
    john_id = john.id
    assert_broadcast "message", %{id: _, body: "the body", created_at: _, user_id: ^john_id, status: "sending"}
    topic = "users:#{mike.id}"
    assert_receive %Phoenix.Socket.Broadcast{
      topic: ^topic,
      event: "message",
      payload: %{id: _, body: "the body", created_at: _, user_id: ^john_id, status: "sending"}
    }
  end

  # TODO
  test "after message is received by the server it sends push notifications to those who are not in the chat" do

  end

  test "When message is received by a recipient, recipient sends the status `received`, and if all statuses are `received` or `read`, it changes the status of the message and pushes it to owner via broadcast or APN", %{socket: socket, users: [john, mike, sam, sara], chat: chat} do
    # connect to `users:...` channel in order to see the status being pushed via `message:status`
    {:ok, _, _user_socket} = subscribe_and_join(socket, "users:#{john.id}", %{})

    # send message to chat channel from john
    send_message(socket, chat, @message_attrs)

    # get last message being stored
    message = get_message()

    # send `received` status from mike
    send_message_status(mike, chat, message, "received")
    statuses = get_message_statuses(message.id)
    assert_statuses([{mike.id, "received"}, {sam.id, "sending"}, {sara.id, "sending"}], statuses)

    # send `received` status from sam
    send_message_status(sam, chat, message, "read")
    statuses = get_message_statuses(message.id)
    assert_statuses([{mike.id, "received"}, {sam.id, "read"}, {sara.id, "sending"}], statuses)

    # send `received` status from sara
    send_message_status(sara, chat, message, "received")
    statuses = get_message_statuses(message.id)
    assert_statuses([{mike.id, "received"}, {sam.id, "read"}, {sara.id, "received"}], statuses)

    # chek that message's status has been changed
    message = get_message(message.id)
    assert %Message{status: "received"} = message

    # assert that the owner of the message has been notified about status change
    message_id = message.id
    assert_push "message:status", %{id: ^message_id, status: "received"}
  end

  test "when message is read, recipient sends the status `read`, which is pushed at owner via broadcast or APN", %{socket: socket, users: [john, mike, sam, sara], chat: chat} do
    # connect to users:... channel in order to see the status being pushed via `message:status`
    {:ok, _, _user_socket} = subscribe_and_join(socket, "users:#{john.id}", %{})

    # send message to chat channel from john
    send_message(socket, chat, @message_attrs)

    # get last message being stored
    message = get_message()

    # send `read` status from mike
    send_message_status(mike, chat, message, "read")
    statuses = get_message_statuses(message.id)
    assert_statuses([{mike.id, "read"}, {sam.id, "sending"}, {sara.id, "sending"}], statuses)

    # send `read` status from sam
    send_message_status(sam, chat, message, "read")
    statuses = get_message_statuses(message.id)
    assert_statuses([{mike.id, "read"}, {sam.id, "read"}, {sara.id, "sending"}], statuses)

    # send `read` status from sara
    send_message_status(sara, chat, message, "read")
    statuses = get_message_statuses(message.id)
    assert_statuses([{mike.id, "read"}, {sam.id, "read"}, {sara.id, "read"}], statuses)

    # chek that message's status has been changed
    message = get_message(message.id)
    assert %Message{status: "read"} = message

    # assert that the owner of the message has been notified about status change
    message_id = message.id
    assert_push "message:status", %{id: ^message_id, status: "read"}
  end

  test "recipient sends the status 'seen' of the last message and all messages in the chat are marked as seen" do
    # TODO
    refute true
  end

  defp assert_statuses(ids_statuses, statuses) do
    statuses_to_assert =
      ids_statuses
      |> Enum.map(fn {id, status} -> %{recipient_id: id, status: status} end)

    statuses_as_map =
      statuses
      |> Enum.map(fn status -> status |> Map.from_struct |> Map.take([:recipient_id, :status])   end)

    assert ^statuses_to_assert = statuses_as_map
  end

  defp send_message(socket, chat, message_attrs) do
    {:ok, _, socket} = subscribe_and_join(socket, "chats:#{chat.id}", %{})
    push socket, "message", message_attrs
    socket
  end

  defp send_message_status(user, chat, message, status) do
    # send `read` status from mike
    {:ok, socket} = connect_with_token(user)
    {:ok, _, socket} = subscribe_and_join(socket, "chats:#{chat.id}", %{})
    push socket, "status", %{"id" => message.id, "status" => status}
  end

  defp connect_with_token(user) do
    {:ok, token, _full_claims} = Guardian.encode_and_sign(user, :token)
    {:ok, socket} = connect(Typi.UserSocket, %{"token" => token})
    {:ok, socket}
  end

  defp get_message(message_id \\ false) do
    :timer.sleep(50)
    if message_id do
      Amnesia.transaction do
        Message.read(message_id)
      end
    else
      Amnesia.transaction do
        Message.last
      end
    end
  end

  defp get_message_statuses(message_id) do
    :timer.sleep(50)
    Amnesia.transaction do
      Status.read_at(message_id, :message_id)
    end
    |> Enum.sort(fn s1, s2 -> s1.recipient_id < s2.recipient_id end)
  end
end
