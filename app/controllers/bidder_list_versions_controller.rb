class BidderListVersionsController < ApplicationController
  after_action :verify_authorized
  before_action :load_project

  rescue_from Pundit::NotAuthorizedError do
    redirect_to root_path, alert: "You don't have access to that project action.", status: :see_other
  end

  def show
    @version = @project.bidder_list_versions.find(params[:id])
    full_access = policy(@project).show? || current_user.has_role?(:admin)
    unless full_access || (current_user.has_role?(:approver) &&
           @project.approvals.exists?(approver: current_user, bidder_list_version: @version))
      raise Pundit::NotAuthorizedError
    end
    authorize @project, :approval_workspace?
    return unless full_access

    versions = @project.bidder_list_versions
    @previous_version = versions.find_by(version_number: @version.version_number - 1)
    @next_version = versions.find_by(version_number: @version.version_number + 1)
  end

  def create
    authorize @project, :manage_item_groups?

    version = @project.with_lock do
      authorize @project, :manage_item_groups?
      groups = @project.item_groups.order(:id).to_a
      selections = GroupSupplier.where(item_group_id: groups.map(&:id), selected: true)
                                .includes(:supplier).order(:id).group_by(&:item_group_id)
      next if selections.empty?

      snapshot = BidderListSnapshot.build(@project, groups: groups, items: @project.items.order(:id), selections: selections)
      latest = @project.bidder_list_versions.order(version_number: :desc).first
      next latest if latest&.snapshot == snapshot

      @project.bidder_list_versions.create!(
        version_number: (latest&.version_number || 0) + 1,
        snapshot: snapshot,
        created_by: current_user
      )
    end

    unless version
      return redirect_to bidder_list_suppliers_project_path(@project),
                         alert: "Select at least one supplier before saving a bidder list.", status: :see_other
    end

    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.refresh(request_id: nil, method: :morph, scroll: :preserve) }
      format.html do
        redirect_to bidder_list_suppliers_project_path(@project),
                    notice: "Bidder list version #{version.version_number} saved.", status: :see_other
      end
    end
  end

  private

  def load_project
    @project = action_name == "show" ? Project.find(params[:project_id]) : policy_scope(Project).find(params[:project_id])
  end
end
