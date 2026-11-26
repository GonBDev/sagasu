require "test_helper"

class ChatsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "participants reuse one private thread and read only incoming messages" do
    first = account("chat-first")
    second = account("chat-second")
    outsider = account("chat-outsider")

    sign_in first
    assert_difference("Chat.count", 1) { post chats_path, params: { recipient_email: second.email.upcase } }
    chat = Chat.for_user(first).sole
    assert_redirected_to chat_path(chat)
    first_message = chat.messages.create!(sender: first, content: "First message")
    reply = chat.messages.create!(sender: second, content: "Reply")

    get messages_path
    assert_select "a[href=?] .badge", chat_path(chat), text: /1 unread/
    get chat_path(chat)
    assert_response :success
    assert_nil first_message.reload.read_at
    assert reply.reload.read_at

    sign_in second
    assert_no_difference("Chat.count") { post chats_path, params: { recipient_email: first.email } }
    assert_redirected_to chat_path(chat)
    get chat_path(chat)
    assert first_message.reload.read_at

    sign_in outsider
    get chat_path(chat)
    assert_response :not_found
  end

  test "personal notes stay private and never become unread" do
    owner = account("notes-owner")
    sign_in owner
    post notes_chats_path
    chat = Chat.for_user(owner).sole
    chat.messages.create!(sender: owner, content: "Private note")
    get messages_path
    assert_select "a[href=?] .badge", chat_path(chat), count: 0
    get chat_path(chat)
    assert_select "div", text: "Private note"
    sign_in account("notes-outsider")
    get chat_path(chat)
    assert_response :not_found
  end

  test "bot displays assigned approvals and owned returned RFQs" do
    buyer = account("task-buyer", :buyer)
    reviewer = account("task-reviewer", :approver)
    other = account("task-other", :approver)
    project = buyer.projects.create!(title: "Pending RFQ", status: :pending_approval)
    returned = buyer.projects.create!(title: "Returned RFQ", status: :returned)
    version = project.bidder_list_versions.create!(created_by: buyer, version_number: 1,
                                                   snapshot: BidderListSnapshot.for_project(project))
    approval = project.approvals.create!(approver: reviewer, bidder_list_version: version)

    sign_in reviewer
    get messages_path
    assert_select "a", text: "Pending RFQ"
    assert_select "a", text: "Returned RFQ", count: 0

    sign_in other
    get messages_path
    assert_select "p", text: "You have no outstanding tasks."

    sign_in buyer
    get messages_path
    assert_select "a", text: "Returned RFQ"
    assert_select "a", text: "Pending RFQ", count: 0

    approval.update!(status: :approved)
    project.approved!
    returned.pending_approval!
    get messages_path
    assert_select "a", text: "Returned RFQ", count: 0
    sign_in reviewer
    get messages_path
    assert_select "p", text: "You have no outstanding tasks."
  end

  test "submitting an approval leaves one unread bot message with a review link" do
    buyer = account("bot-message-buyer", :buyer)
    reviewer = account("bot-message-reviewer", :approver)
    project = buyer.projects.create!(title: "Review this RFQ")
    version = project.bidder_list_versions.create!(created_by: buyer, version_number: 1,
                                                   snapshot: BidderListSnapshot.for_project(project))
    sign_in buyer
    assert_difference ["Approval.count", "Task.count", "Message.count"], 1 do
      post submit_bidder_list_approval_project_path(project),
           params: { bidder_list_version_id: version.id, approver_id: reviewer.id }
    end

    chat = Chat.for_user(reviewer).sole
    message = chat.messages.sole
    assert_equal buyer, message.sender
    assert_equal reviewer, message.task.assignee
    assert_equal version, message.task.actionable.bidder_list_version
    assert_nil message.read_at

    assert_no_difference ["Approval.count", "Task.count", "Message.count"] do
      post submit_bidder_list_approval_project_path(project),
           params: { bidder_list_version_id: version.id, approver_id: reviewer.id }
    end

    sign_in reviewer
    get messages_path
    assert_select "a[href=?] .badge", chat_path(chat), text: /1 unread/
    get chat_path(chat)
    assert_select "strong", "Sagasu Bot"
    assert_select "a[href=?]", bidder_list_approval_project_path(project), text: "Open approval"
    assert message.reload.read_at
    assert message.task.pending?

    sign_in account("bot-message-outsider")
    get chat_path(chat)
    assert_response :not_found
  end

  private

  def account(name, role = :base)
    User.create!(email: "#{name}@example.test", password: "test-password").tap { |user| user.user_roles.create!(role: role) }
  end
end
