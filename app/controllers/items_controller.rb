class ItemsController < ApplicationController
  after_action :verify_authorized
  rescue_from Pundit::NotAuthorizedError, with: :material_access_denied

  before_action :load_material_for_edit, only: %i[edit update]

  def create
    @project = current_user.projects.find(params[:project_id])
    authorize @project, :add_material?

    @item = @project.items.build(item_params)

    if @item.save
      redirect_to project_path(@project), notice: "Material added.", status: :see_other
    else
      @items = @project.items.order(:id)
      render "projects/show", status: 422
    end
  end

  def edit
  end

  def update
    if @item.update(item_params)
      redirect_to project_path(@project), notice: "Material updated.", status: :see_other
    else
      render :edit, status: 422
    end
  end

  private

  def item_params
    params.require(:item).permit(:erp_material, :description, :quantity, :unit_of_measure)
  end

  def material_access_denied
    redirect_to project_path(@project),
                alert: "You can only change materials on your own draft RFQs.",
                status: :see_other
  end

  def load_material_for_edit
    @project = current_user.projects.find(params[:project_id])
    authorize @project, :edit_material?
    @item = @project.items.find(params[:id])
  end
end
