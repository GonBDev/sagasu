class ApprovalPolicy < ApplicationPolicy
  def index?
    user.has_role?(:approver) || user.has_role?(:admin)
  end

  def decide?
    user.id == record.approver_id && user.has_role?(:approver) &&
      record.bidder_list_version_id.present? && record.pending? && record.project.pending_approval?
  end
end
