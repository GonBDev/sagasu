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
    attributes = item_params # Keep the submitted material fields.
    if attributes.key?(:item_group_id) # Preserve the current group when the regular edit form omits it.
      group_id = attributes.delete(:item_group_id) # Resolve the submitted ID through the current project.
      # A nonblank ID must belong to this RFQ.
      attributes[:item_group] = @project.item_groups.find(group_id) if group_id.present?
      attributes[:item_group] = nil if group_id.blank? # A blank selection moves the material to Ungrouped.
    end
    if @item.update(attributes) # Save the material changes and any new assignment.
      redirect_to project_path(@project), notice: "Material updated.", status: :see_other
    else
      render :edit, status: 422
    end
  end

  private

  def item_params
    params.require(:item).permit(:erp_material, :description, :quantity,
                                 :unit_of_measure, :item_group_id)
    # Accept a group assignment from the move form.
  end

  def material_access_denied
    redirect_to project_path(@project),
                lert: "You can only change materials on your own draft or returned RFQs.", # Match the policy's editable statuses.
                status: :see_other
  end

  def load_material_for_edit
    @project = current_user.projects.find(params[:project_id])
    authorize @project, :edit_material?
    @item = @project.items.find(params[:id])
  end
end
