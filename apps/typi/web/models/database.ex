use Amnesia

defdatabase Typi.Database do
  deftable Message, [
    {:id, autoincrement },
    :body,
    :client_id,
    :chat_id,
    :created_at,
    :publish_at,
    :show_true_date,
    :status,
    :user_id
  ], type: :set, index: [:chat_id] do
		#Nice to have, we declare a struct that represents a record in the database
    @type t :: %Message{
      id: non_neg_integer,
      body: String.t,
      client_id: non_neg_integer,
      chat_id: non_neg_integer,
      created_at: non_neg_integer,
      publish_at: non_neg_integer,
      show_true_date: boolean,
      status: String.t,
      user_id: non_neg_integer
    }
  end

  deftable Status, [
    {:id, autoincrement },
    :message_id,
    :recipient_id,
    :status
  ], type: :set, index: [:message_id] do
    @type t :: %Status{
      id: non_neg_integer,
      message_id: non_neg_integer,
      recipient_id: non_neg_integer,
      status: String.t
    }
  end
end
