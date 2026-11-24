class ProjectsController < ApplicationController
  after_action :verify_authorized, except: :index
  after_action :verify_policy_scoped, only: :index

  rescue_from Pundit::NotAuthorizedError, with: :project_access_denied

  def new
    @project = current_user.projects.build
    authorize @project
  end

  def create
    @project = current_user.projects.build(project_params)
    authorize @project

    if @project.save
      redirect_to project_path(@project), notice: "RFQ draft created.", status: :see_other
    else
      render :new, status: 422
    end
  end

  def show
    @project = current_user.projects.find(params[:id])
    authorize @project
    @item = @project.items.build
    @items = @project.items.order(:id)
  end

  def index
    @query = params[:q].to_s.strip
    @projects = policy_scope(Project).order(updated_at: :desc)

    return unless @query.present?

    term = Project.sanitize_sql_like(@query)
    @projects = @projects.where("title ILIKE ?", "%#{term}%")
  end

  private

  def project_access_denied
    redirect_to root_path, alert: "You don't have access to that RFQ action.",
                           status: :see_other
  end

  def project_params
    params.require(:project).permit(
      :title, :erp_rfq, :scope, :client_name, :client_area,
      :budget_amount, :budget_currency, :buyer_comment
    )
  end
end
