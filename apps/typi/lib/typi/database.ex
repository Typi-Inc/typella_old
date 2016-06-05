use Amnesia

defdatabase Database do
  deftable Message, [
    {:id, autoincrement },
    :body,
    :client_id,
    :chat_id,
    :created_at,
    :publish_at,
    :status,
    :user_id
  ], type: :bag, index: [:chat_id] do
		#Nice to have, we declare a struct that represents a record in the database
    @type t :: %Message{
      id: non_neg_integer,
      body: String.t,
      client_id: non_neg_integer,
      chat_id: non_neg_integer,
      created_at: non_neg_integer,
      publish_at: non_neg_integer,
      status: String.t,
      user_id: non_neg_integer
    }
  end
end
