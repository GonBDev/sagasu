class Approval < ApplicationRecord
  belongs_to :project
  belongs_to :bidder_list_version, optional: true
  validate :bidder_list_version_matches_project

  attr_readonly :bidder_list_version_id
  belongs_to :approver, class_name: "User", inverse_of: :approvals

  enum :status, {
    pending: "pending",
    approved: "approved",
    returned: "returned"
  }, validate: true

  attr_readonly :snapshot

  def notify_reviewer!
    buyer = project.user
    version_number = bidder_list_version.version_number
    title = bidder_list_version.snapshot.fetch("project").fetch("title")
    task = Task.create!(assignee: approver, actionable: self, kind: :review_bidder_list)

    Chat.between(buyer, approver).messages.create!(
      task: task, sender: buyer,
      content: "Please review bidder list version #{version_number} for #{title.truncate(250)}."
    )
  end

  private

  def bidder_list_version_matches_project
    return unless bidder_list_version && bidder_list_version.project_id != project_id

    errors.add(:bidder_list_version, "must belong to the same RFQ")
  end
end
