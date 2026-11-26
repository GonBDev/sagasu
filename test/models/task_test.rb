require "test_helper"

class TaskTest < ActiveSupport::TestCase
  test "approval task follows the review status independently of message read state" do
    owner = User.create!(email: "task-owner@example.test", password: "test-password")
    reviewer = User.create!(email: "task-assignee@example.test", password: "test-password")
    project = owner.projects.create!(title: "Task RFQ", status: :pending_approval)
    approval = project.approvals.create!(approver: reviewer)
    task = Task.create!(assignee: reviewer, actionable: approval, kind: :review_bidder_list)
    message = Chat.between(owner, reviewer).messages.create!(sender: owner, content: "Review requested", task: task)

    assert task.pending?
    message.update!(read_at: Time.current)
    assert task.pending?
    approval.returned!
    assert_not task.pending?
    assert_equal task, message.reload.task
  end
end
