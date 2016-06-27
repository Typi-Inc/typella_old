defmodule Typi.FutureMessage do
	use GenServer
	use Amnesia
	import Logger
	use Typi.Database

	@interval Application.get_env(:typi, :future_message)

	def start_link(name) do
  	  GenServer.start_link(__MODULE__, :ok, name: name)
  	end

  	def init(state) do
    	Process.send_after(self(), :work, 20000)
   		{:ok, state}
 	end

 	def handle_info(:work, state) do
 		messages=messages_to_send
 		# task = Task.async(fn -> set_future_handled(messages) end)
 		# Task.await(task)
 		set_future_handled(messages)
 		# broadcast_messages_to_send(messages_to_send)
    	Process.send_after(self(), :work, 20000)
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
		now = :os.system_time(:milli_seconds)+30000
		messages=[]
		Amnesia.transaction do
			selection = Message.where publish_at <= now and future_handled==false,
				select: id
			messages = selection
			|> Amnesia.Selection.values
			|> Enum.map(&Message.read(&1))
			# IO.inspect messages
			messages
		end
	end

	# def broadcast_messages_to_send(messages) do

	# end


end
