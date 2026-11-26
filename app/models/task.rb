class Task < ApplicationRecord
  belongs_to :assignee, class_name: "User"
  belongs_to :actionable, polymorphic: true

  enum :kind, { review_bidder_list: "review_bidder_list" }, validate: true
  validate :approval_review_matches_assignee

  def pending?
    review_bidder_list? && actionable&.pending? && actionable.project.pending_approval?
  end

  private

  def approval_review_matches_assignee
    return unless review_bidder_list?
    return if actionable.is_a?(Approval) && actionable.approver_id == assignee_id

    errors.add(:actionable, "must be an approval assigned to this reviewer")
  end
end
