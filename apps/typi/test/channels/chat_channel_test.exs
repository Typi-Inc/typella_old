defmodule Typi.ChatChannelTest do
  use Typi.ChannelCase
  use Amnesia
  use Database

  @message_attrs  %{body: "the body", client_id: 1, created_at: :os.system_time(:seconds)}

  setup do
    john = insert_user
    mike = insert_user
    sam = insert_user
    chat = insert_chat(%Typi.Chat{
      users: [john, mike, sam]
    })
    {:ok, token, _full_claims} = Guardian.encode_and_sign(john, :token)
    {:ok, socket} = connect(Typi.UserSocket, %{"token" => token})
    {:ok, socket: socket, users: [john, mike, sam], chat: chat}
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

  test "server receives message, stores it, creates status entries and replies with `sending` status", %{socket: socket, users: [john, mike, sam], chat: chat} do
    {:ok, _, socket} = subscribe_and_join(socket, "chats:#{chat.id}", %{})
    ref = push socket, "message", @message_attrs
    assert_reply ref, :ok, %{id: _, client_id: 1, status: "sending"}

    :timer.sleep(50)
    [message] = Amnesia.transaction do
      Message.read_at(chat.id, :chat_id)
    end
    chat_id = chat.id
    john_id = john.id
    assert %Message{body: "the body", client_id: 1, chat_id: ^chat_id, status: "sending", user_id: ^john_id} = message

    mike_id = mike.id
    sam_id = sam.id
    :timer.sleep(50)
    statuses = Amnesia.transaction do
      Status.read_at(message.id, :message_id)
    end
    |> Enum.sort(fn s1, s2 -> s1.recipient_id < s2.recipient_id end)
    assert length(statuses) == 2
    assert [%Status{recipient_id: ^mike_id, status: "sending"}, %Status{recipient_id: ^sam_id, status: "sending"}] = statuses

    cleanup
  end

  test "after message is received server checks the presence of recipients, if all recipients are in the same chat then broadcasts to recipients", %{socket: socket, users: [john, _mike, _sam], chat: chat} do
    {:ok, _, socket} = subscribe_and_join(socket, "chats:#{chat.id}", %{})
    _ref = push socket, "message", @message_attrs
    john_id = john.id
    assert_broadcast "message", %{id: _, body: "the body", created_at: _, user_id: ^john_id, status: "sending"}

    cleanup
  end

  test "When message is received by a recipient, recipient sends the status `received`, and if all statuses are `received`, it changes the status of the message and pushes it to owner", %{socket: socket, users: [john, mike, sam], chat: chat} do
    #  send message to chat channel from john
    {:ok, _, socket} = subscribe_and_join(socket, "chats:#{chat.id}", %{})
    {:ok, _, user_socket} = subscribe_and_join(socket, "users:#{john.id}", %{})
    _ref = push socket, "message", @message_attrs
    :timer.sleep(100)
    message = Amnesia.transaction do
      Message.last
    end
    {:ok, token, _full_claims} = Guardian.encode_and_sign(mike, :token)
    {:ok, socket} = connect(Typi.UserSocket, %{"token" => token})
    {:ok, _, socket} = subscribe_and_join(socket, "chats:#{chat.id}", %{})
    _ref = push socket, "status", %{"id" => message.id, "status" => "received"}
    :timer.sleep(50)
    statuses = Amnesia.transaction do
      Status.read_at(message.id, :message_id)
    end
    |> Enum.sort(fn s1, s2 -> s1.recipient_id < s2.recipient_id end)
    mike_id = mike.id
    sam_id = sam.id
    # assert length(statuses) == 2
    assert [%Status{recipient_id: ^mike_id, status: "received"}, %Status{recipient_id: ^sam_id, status: "sending"}] = statuses

    {:ok, token, _full_claims} = Guardian.encode_and_sign(sam, :token)
    {:ok, socket} = connect(Typi.UserSocket, %{"token" => token})
    {:ok, _, socket} = subscribe_and_join(socket, "chats:#{chat.id}", %{})
    _ref = push socket, "status", %{id: message.id, status: "received"}

    :timer.sleep(50)
    statuses = Amnesia.transaction do
      Status.read_at(message.id, :message_id)
    end
    |> Enum.sort(fn s1, s2 -> s1.recipient_id < s2.recipient_id end)
    mike_id = mike.id
    sam_id = sam.id
    assert [%Status{recipient_id: ^mike_id, status: "received"}, %Status{recipient_id: ^sam_id, status: "received"}] = statuses
    :timer.sleep(50)
    message = Amnesia.transaction do
      Message.read(message.id)
    end
    assert %Message{status: "received"} = message
    message_id = message.id
    assert_push "message:status", %{id: ^message_id, status: received}

    cleanup
  end

  test "when message is read, recipient sends the status `read`, which is pushed at sender and the server deletes message" do
    
  end

  defp cleanup() do
    :timer.sleep(50)
    Amnesia.transaction do
      message = Message.last
      statuses = Status.read_at(message.id, :message_id)
      unless is_nil(statuses) do
        for status <- statuses do
          status |> Status.delete
        end
      end
      message |> Message.delete
    end
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
