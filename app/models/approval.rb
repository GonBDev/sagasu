class Approval < ApplicationRecord
  belongs_to :project
  belongs_to :approver, class_name: "User", inverse_of: :approvals

  enum :status, {
    pending: "pending",
    approved: "approved",
    returned: "returned"
  }, validate: true

  attr_readonly :snapshot
end
