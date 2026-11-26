class DashboardsController < ApplicationController
  after_action :verify_policy_scoped

  def show
    visible_projects = policy_scope(Project)
    @status_counts = visible_projects.group(:status).count
    @project_count = @status_counts.values.sum
    @selection_count = selected_suppliers(visible_projects.select(:id)).count
    @unread_count = Message.where(chat_id: Chat.for_user(current_user).select(:id), read_at: nil)
                           .where.not(sender: current_user).count

    @status = params[:status].presence_in(Project.statuses.keys)
    projects = @status ? visible_projects.where(status: @status) : visible_projects
    @projects = projects.order(updated_at: :desc, id: :desc).limit(12).to_a
    load_project_counts
    load_tasks
  end

  private

  def selected_suppliers(project_ids)
    GroupSupplier.joins(:item_group).where(selected: true, item_groups: { project_id: project_ids })
  end

  def load_project_counts
    ids = @projects.map(&:id)
    items = Item.where(project_id: ids)
    @material_counts = items.group(:project_id).count
    @grouped_counts = items.where.not(item_group_id: nil).group(:project_id).count
    @group_counts = ItemGroup.where(project_id: ids).group(:project_id).count
    @selection_counts = selected_suppliers(ids).group("item_groups.project_id").count
  end

  def load_tasks
    @pending_approvals = if current_user.has_role?(:approver)
      current_user.approvals.pending.joins(:project).where(projects: { status: :pending_approval })
                  .where.not(bidder_list_version_id: nil).includes(:bidder_list_version).order(:created_at, :id).limit(5)
    else
      Approval.none
    end
    @returned_projects = if current_user.has_role?(:buyer)
      current_user.projects.returned.order(updated_at: :desc, id: :desc).limit(5)
    else
      Project.none
    end
  end
end
