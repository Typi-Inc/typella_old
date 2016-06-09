defmodule Typi.UserChannelTest do
  use Typi.ChannelCase

  setup do
    user = insert_user
    {:ok, token, _full_claims} = Guardian.encode_and_sign(user, :token)
    {:ok, socket} = connect(Typi.UserSocket, %{"token" => token})
    {:ok, _, socket} = subscribe_and_join(socket, "users:#{user.id}", %{})
    {:ok, socket: socket, user: user}
  end
  
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
