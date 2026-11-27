class ProjectsController < ApplicationController
  after_action :verify_authorized, except: :index
  after_action :verify_policy_scoped, only: :index

  rescue_from Pundit::NotAuthorizedError, with: :project_access_denied
  before_action :load_project_for_edit, only: %i[edit update]

  def new
    @project = current_user.projects.build
    authorize @project
  end

  def smart_fill
    authorize Project, :create?
    render json: { fields: ProjectSmartFill.new(params[:smart_fill_text]).call }
  rescue Pundit::NotAuthorizedError
    render json: { error: "You don’t have permission to create projects." }, status: :forbidden
  rescue ProjectSmartFill::InvalidInput => error
    render json: { error: error.message }, status: 422
  rescue ProjectSmartFill::InvalidResponse, RubyLLM::Error, RubyLLM::ConfigurationError, Faraday::Error, KeyError
    render json: { error: "Smart Fill couldn’t process the text. Try again or enter the details manually." },
           status: :service_unavailable
  end

  def create
    @project = current_user.projects.build(project_params)
    authorize @project

    if @project.save
      redirect_to project_path(@project), notice: "Draft supply project created.", status: :see_other
    else
      render :new, status: 422
    end
  end

  def edit
    authorize @project
    render :new
  end

  def update
    saved = @project.with_lock do
      authorize @project
      @project.update(project_params)
    end

    if saved
      redirect_to project_path(@project), notice: "Project information updated.", status: :see_other
    else
      render :new, status: 422
    end
  end

  def show
    if request.path_parameters[:workspace_step] == "approval"
      @project = Project.find(params[:id])
      authorize @project, :approval_workspace?
      load_approval_workspace
    else
      @project = policy_scope(Project).find(params[:id])
      authorize @project
    end
    @item = @project.items.build
    @items = @project.items.order(:id)

    if request.path_parameters[:workspace_step] == "suppliers"
      load_supplier_workspace
    end

    if params[:proposal_id].present? && policy(@project).manage_item_groups?
      run = AiRun.grouping.find_by!(
        id: params[:proposal_id], project: @project, user: current_user, status: "completed"
      )
      @proposed_groups = JSON.parse(run.output)
      @proposal_id = run.id
    end
  end

  def submit_approval
    @project = Project.find(params[:id])
    authorize @project, :submit_approval?

    alert = @project.with_lock do
      authorize @project, :submit_approval?
      if @project.approvals.pending.exists?
        next "This project already has a pending approval."
      end

      latest = @project.bidder_list_versions.order(version_number: :desc).first
      if latest.nil? || latest.id.to_s != params[:bidder_list_version_id] ||
         latest.snapshot != BidderListSnapshot.for_project(@project)
        next "Save the current bidder list in Suppliers before submitting it."
      end

      approver = eligible_approvers.find_by(id: params[:approver_id])
      next "Choose a user with the Approver grant." unless approver

      approval = @project.approvals.create!(approver: approver, bidder_list_version: latest)
      @project.pending_approval!
      approval.notify_reviewer!
      nil
    end

    if alert
      redirect_to bidder_list_approval_project_path(@project), alert: alert, status: :see_other
    else
      redirect_to bidder_list_approval_project_path(@project), notice: "Bidder list submitted for approval.", status: :see_other
    end
  end

  def index
    @query = params[:q].to_s.strip
    @status = params[:status].presence_in(Project.statuses.keys)
    projects = policy_scope(Project)

    if @query.present?
      term = Project.sanitize_sql_like(@query)
      projects = projects.where("title ILIKE ?", "%#{term}%")
    end

    @status_counts = projects.group(:status).count
    projects = projects.where(status: @status) if @status
    @projects = projects.order(updated_at: :desc, id: :desc).to_a
    load_index_card_counts
  end

  private

  def load_index_card_counts
    project_ids = @projects.map(&:id)
    items = Item.where(project_id: project_ids)
    @material_counts = items.group(:project_id).count
    @grouped_counts = items.where.not(item_group_id: nil).group(:project_id).count
    @group_counts = ItemGroup.where(project_id: project_ids).group(:project_id).count
    @selection_counts = GroupSupplier.joins(:item_group)
                                     .where(selected: true, item_groups: { project_id: project_ids })
                                     .group("item_groups.project_id").count
  end

  def load_project_for_edit
    @project = current_user.projects.find(params[:id])
  end

  def load_approval_workspace
    approvals = @project.approvals.includes(:approver, :bidder_list_version)
    full_access = policy(@project).show? || current_user.has_role?(:admin)
    if full_access
      @review_state = approvals.order(created_at: :desc, id: :desc).first
    else
      @review_state = approvals.where(approver: current_user).order(created_at: :desc, id: :desc).first
    end

    if full_access && (@project.draft? || @project.returned?)
      latest_saved_version = @project.bidder_list_versions.order(version_number: :desc).first
    end
    @bidder_list_summary_version = latest_saved_version || @review_state&.bidder_list_version

    load_supplier_invitations if policy(@project).prepare_supplier_invitations?

    return unless policy(@project).submit_approval?

    @submission_version = latest_saved_version
    @submission_outdated = @submission_version && @submission_version.snapshot != BidderListSnapshot.for_project(@project)
    @eligible_approvers = eligible_approvers.order(:name, :email)
  end

  def load_supplier_invitations
    return unless @review_state&.approved? && @review_state.bidder_list_version

    @supplier_invitations = SupplierInvitations.new(@review_state.bidder_list_version).call
  rescue SupplierInvitations::TemplateError => error
    @supplier_invitation_error = error.message
  end

  def eligible_approvers
    User.where(id: UserRole.approver.select(:user_id)).where.not(id: [current_user.id, @project.user_id])
  end

  def load_supplier_workspace
    entries = GroupSupplier.where(item_group_id: @project.item_groups.select(:id))
                           .where("ai_suggested = ? OR selected = ?", true, true)
                           .includes(:supplier).order(:id).to_a
    @supplier_suggestions_by_group = entries.select(&:ai_suggested?).group_by(&:item_group_id)
    @selected_suppliers_by_group = entries.select(&:selected?).group_by(&:item_group_id)
    @latest_bidder_list_version = @project.bidder_list_versions.order(version_number: :desc).first
    if @latest_bidder_list_version
      draft_snapshot = BidderListSnapshot.build(
        @project, groups: @project.item_groups.order(:id), items: @items, selections: @selected_suppliers_by_group
      )
      @bidder_list_unsaved = @latest_bidder_list_version.snapshot != draft_snapshot
    end

    return unless policy(@project).manage_item_groups? && params[:supplier_group_id].present?

    @supplier_search_group = @project.item_groups.find(params[:supplier_group_id])
    @supplier_query = params[:q].to_s.strip
    @supplier_search_results = Supplier.search_catalog(@supplier_query).limit(25) if @supplier_query.present?
  end

  def project_access_denied
    redirect_to root_path, alert: "You don't have access to that project action.",
                           status: :see_other
  end

  def project_params
    params.require(:project).permit(
      :title, :erp_rfq, :scope, :client_name, :client_area,
      :budget_amount, :budget_currency, :buyer_comment
    )
  end
end
