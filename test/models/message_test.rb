require "test_helper"

class MessageTest < ActiveSupport::TestCase
  test "sender must be a participant" do
    first = User.create!(email: "model-message-first@example.test", password: "test-password")
    outsider = User.create!(email: "model-message-outsider@example.test", password: "test-password")
    chat = Chat.between(first, first)
    message = chat.messages.build(sender: outsider, content: "Private")
    assert_not message.valid?
    assert_includes message.errors[:sender], "must be a conversation participant"
  end
end
