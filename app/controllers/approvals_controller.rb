class ApprovalsController < ApplicationController
  after_action :verify_authorized

  rescue_from Pundit::NotAuthorizedError do
    head :forbidden
  end

  def index
    authorize Approval
    @approvals = Approval.pending.joins(:project)
                         .where(projects: { status: :pending_approval })
                         .where.not(bidder_list_version_id: nil)
                         .includes(:approver, :bidder_list_version, project: :user)
                         .order(:created_at, :id)
    @show_approvers = current_user.has_role?(:admin)
    @approvals = @approvals.where(approver: current_user) unless @show_approvers
  end

  def decide
    approval = Approval.find(params[:id])
    authorize approval

    decision = params[:decision]
    comment = params[:comment].to_s.strip
    unless %w[approved returned].include?(decision) && comment.present?
      return redirect_to bidder_list_approval_project_path(approval.project_id),
                         alert: "Choose a decision and enter a comment.", status: :see_other
    end

    project = approval.project
    project.with_lock do
      approval.lock!
      authorize approval
      approval.update!(status: decision, comment: comment, decided_at: Time.current)
      project.update!(status: decision)
    end

    notice = approval.approved? ? "Bidder list approved." : "Bidder list returned to the buyer."
    redirect_to bidder_list_approval_project_path(project), notice: notice, status: :see_other
  end
end
