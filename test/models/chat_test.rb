require "test_helper"

class ChatTest < ActiveSupport::TestCase
  test "participant order does not create a second thread" do
    first = User.create!(email: "model-chat-first@example.test", password: "test-password")
    second = User.create!(email: "model-chat-second@example.test", password: "test-password")
    assert_equal Chat.between(first, second), Chat.between(second, first)
  end
end
