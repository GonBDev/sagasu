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

  def preview_import
    load_material_import_project
    @material_import_text = params[:materials_text].to_s
    @material_import = MaterialImport.parse(@material_import_text)
    if @material_import.valid?
      @material_import_token = material_import_verifier.generate(
        { "project_id" => @project.id, "user_id" => current_user.id, "text" => @material_import_text },
        purpose: :material_import, expires_in: 15.minutes
      )
    end
    render_material_import(@material_import.valid? ? :ok : 422)
  end

  def import
    load_material_import_project
    payload = material_import_verifier.verified(params[:material_import_token].to_s, purpose: :material_import)
    unless payload && payload["project_id"] == @project.id && payload["user_id"] == current_user.id
      return redirect_to bidder_list_materials_project_path(@project),
                         alert: "Review the pasted materials again before importing.", status: :see_other
    end

    @material_import_text = payload.fetch("text")
    @material_import = MaterialImport.parse(@material_import_text)
    return render_material_import(422) unless @material_import.valid?

    @project.with_lock do
      authorize @project, :add_material?
      @project.items.create!(@material_import.rows)
    end

    redirect_to bidder_list_materials_project_path(@project), notice: "Materials imported.", status: :see_other
  rescue ActiveRecord::RecordInvalid => error
    @material_import.errors << error.record.errors.full_messages.to_sentence
    render_material_import(422)
  end

  def edit
  end

  def update
    attributes = item_params # Keep the submitted material fields.
    moving_material = attributes.key?(:item_group_id)
    if moving_material # Preserve the current group when the regular edit form omits it.
      group_id = attributes.delete(:item_group_id) # Resolve the submitted ID through the current project.
      # A nonblank ID must belong to this RFQ.
      attributes[:item_group] = @project.item_groups.find(group_id) if group_id.present?
      attributes[:item_group] = nil if group_id.blank? # A blank selection moves the material to Ungrouped.
    end
    if @item.update(attributes) # Save the material changes and any new assignment.
      destination = moving_material ? bidder_list_groups_project_path(@project) : bidder_list_materials_project_path(@project)
      redirect_to destination, notice: "Material updated.", status: :see_other
    else
      render :edit, status: 422
    end
  end

  private

  def load_material_import_project
    @project = current_user.projects.find(params[:project_id])
    authorize @project, :add_material?
  end

  def material_import_verifier
    Rails.application.message_verifier(:material_import)
  end

  def render_material_import(status)
    @item = @project.items.build
    @items = @project.items.order(:id)
    render "projects/show", status: status
  end

  def item_params
    params.require(:item).permit(:erp_material, :description, :quantity,
                                 :unit_of_measure, :item_group_id)
    # Accept a group assignment from the move form.
  end

  def material_access_denied
    redirect_to project_path(@project),
                alert: "You can only change materials on your own draft or returned RFQs.", # Show why the material change was denied.
                status: :see_other
  end

  def load_material_for_edit
    @project = current_user.projects.find(params[:project_id])
    authorize @project, :edit_material?
    @item = @project.items.find(params[:id])
  end
end
