class NullAdapter
  def authenticate(room_id, token)
    yield Talker::User.new("id" => token, "name" => "user#{token}", "email" => "user#{token}@example.com")
  end
  
  def store_connection(room_id, user_id, state)
  end
  
  def update_connection(room_id, user_id, state)
  end

  def delete_connection(room_id, user_id)
  end
  
  def load_connections(&callback)
  end
end

Talker.storage = NullAdapter.new