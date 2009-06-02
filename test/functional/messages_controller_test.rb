require File.dirname(__FILE__) + "/../test_helper"

class MessagesControllerTest < ActionController::TestCase
  def setup
    login_as :quentin
    subdomain :master
    @room = rooms(:main)
  end
  
  def test_create
    Room.any_instance.expects(:send_data).with(instance_of(String))
    post :create, :room_id => @room, :message => "test"
    assert_response :success
    assert_equal "test", assigns(:message).message
    assert_equal users(:quentin), assigns(:message).user
    assert_equal @room, assigns(:message).room
    assert_match "text/javascript", @response.headers["Content-Type"]
  end
end