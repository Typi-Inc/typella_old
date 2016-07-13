defmodule Typi.FutureMessage do
	use GenServer
	use Amnesia
	use Typi.Database

	@interval Application.get_env(:typi, :future_message)

	def start_link(name) do
  	  GenServer.start_link(__MODULE__, :ok, name: name)
  	end

  	def init(state) do
    	Process.send_after(self(), :work, 1000)
   		{:ok, state}
 	end

 	def handle_info(:work, state) do
 		messages=messages_to_send
    set_future_handled(messages)
    broadcast_messages(messages)
    Process.send_after(self(), :work, 1000)
    {:noreply, state}
  end

  def handle_info(_, state) do
  	{:noreply, state}
  end

  	def set_future_handled(messages) do
  		Amnesia.transaction do
  			for message <- messages do
  				message
  				|> Map.put(:future_handled, true)
  				|> Message.write
  			end
  		end
  	end

	def messages_to_send do
		now = :os.system_time(:milli_seconds)
		Amnesia.transaction do
			selection = Message.where publish_at<=now and future_handled==false,
				select: id
			messages = selection
			|> Amnesia.Selection.values
			|> Enum.map(&Message.read(&1))
      IO.puts "Messages are #{inspect messages}"
			messages
		end
	end

	def sort(messages) do
		Enum.sort(messages, fn(m1,m2) ->
			if abs(m1.publish_at-m2.publish_at)<30000 do
				m1.created_at < m2.created_at
			else
				m1.publish_at < m2.publish_at
			end
		end)
	end

	def broadcast_messages(messages) do
		for message <- sort(messages) do
			Typi.Endpoint.broadcast "chats:#{message.chat_id}", "fm", message
		end
	end

end
