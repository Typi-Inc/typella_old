defmodule Typi.FutureMessageTest do
  use ExUnit.Case, async: true
  alias Typi.Repo
  import Typi.Router.Helpers
  use Amnesia
  use Typi.Database

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
    Amnesia.transaction do
      for _ <- 1..10 do
        insert_random_message
      end
      %Message{
        body: "Hello",
        publish_at: :os.system_time(:milli_seconds) + 30110,
        future_handled: false
      }
      |> Message.write
    end
    :ok
  end

  test "testing messages to send function" do
    # Typi.FutureMessage.start_link(Typi.FutureMessage)
    messages=Typi.FutureMessage.messages_to_send
    # IO.inspect messages
    assert length(messages) == 10

  end

  test "testing set_future_handled function" do
     messages=Typi.FutureMessage.messages_to_send
     Typi.FutureMessage.set_future_handled(messages)
     Amnesia.transaction do
       for message <- messages do
         m=Message.read(message.id)
         assert m.future_handled==true
       end
     end
  end

  test "testing the process sends two times" do
    Typi.FutureMessage.start_link(Typi.FutureMessage)
    :timer.sleep(110)
    IO.puts "first time"
    Amnesia.transaction do
       for id <- 1..10 do
         m=Message.read(id)
         assert m.future_handled==true
       end
       m = Message.read(11)
       # refute m.future_handled
     end
     :timer.sleep(110)
     IO.puts "second time"
    Amnesia.transaction do
       m = Message.last
       assert m.future_handled
     end



  end

  defp insert_random_message() do
    %Message{
      body: "Hello",
      publish_at: :os.system_time(:milli_seconds) + random_number,
      future_handled: false
    }
    |> Message.write
  end

  defp random_number() do
    :random.seed(:os.timestamp)
    round(:random.uniform * 9000) + 1000
  end

  #
  # test "changeset with invalid attributes" do
  #   changeset = Chat.changeset(%Chat{}, @invalid_attrs)
  #   refute changeset.valid?
  # end
end
