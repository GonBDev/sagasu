require "test_helper"

class MessagesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "only participants can post and the signed-in user is the sender" do
    first, second, outsider = %w[first second outsider].map do |name|
      User.create!(email: "message-#{name}@example.test", password: "test-password")
    end
    chat = Chat.between(first, second)
    endpoint = chat_messages_path(chat)

    sign_in outsider
    assert_no_difference("Message.count") do
      post endpoint, params: { message: { content: "Unauthorized" } }
      assert_response :not_found
    end

    sign_in first
    assert_difference("Message.count", 1) do
      post endpoint, params: { message: { content: "<script>alert('hello')</script>", sender_id: second.id } }
      assert_response :see_other
    end
    assert_equal first, chat.messages.sole.sender
    follow_redirect!
    assert_select "script", text: "alert('hello')", count: 0
    assert_includes response.body, "&lt;script&gt;"
  end
end
