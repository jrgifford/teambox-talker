require File.dirname(__FILE__) + "/spec_helper"

describe "'message' message" do
  before do
    @connection = create_connection
  end
  
  it "should require active connection" do
    message = { "type" => "message", "id" => "id", "content" => "ohaie" }
    @connection.should_receive(:error)
    @connection.mock_message_received(message)
  end
  
  it "should be broadcasted to room" do
    connect "test", "user_id", "tester"

    message = { "type" => "message", "id" => "mid", "content" => "ohaie" }
    sent_message = { "type" => "message", "id" => "mid", "content" => "ohaie", "from" => "user_id" }
    @connection.room.should_receive(:send_message).
                     with { |json| decode(json) == sent_message }
    
    @connection.mock_message_received(message)
  end
  
  it "should be send as private" do
    connect "test", "user_id", "tester"

    message = { "type" => "message", "id" => "mid", "content" => "ohaie", "to" => "bob" }
    sent_message = { "type" => "message", "id" => "mid", "content" => "ohaie", "from" => "user_id", "private" => true }
    @connection.room.should_receive(:send_private_message).
                     with { |to, json| to == "bob" && decode(json) == sent_message }
    
    @connection.mock_message_received(message)
  end
end
