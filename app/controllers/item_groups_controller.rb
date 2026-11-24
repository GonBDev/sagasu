class ItemGroupsController < ApplicationController
  after_action :verify_authorized

  before_action :load_project
  before_action :load_item_group, only: %i[update destroy]

  def create
    @item_group = @project.item_groups.build(item_group_params)

    if @item_group.save
      redirect_to project_path(@project), notice: "Group created.", status: :see_other
    else
      redirect_to project_path(@project), alert: @item_group.errors.full_messages.to_sentence,
                                          status: :see_other
    end
  end

  def update
    if @item_group.update(item_group_params)
      redirect_to project_path(@project), notice: "Group renamed.", status: :see_other
    else
      redirect_to project_path(@project), alert: @item_group.errors.full_messages.to_sentence,
                                          status: :see_other
    end
  end

  def destroy
    ItemGroup.transaction do
      @item_group.items.update_all(item_group_id: nil, updated_at: Time.current)
      @item_group.destroy!
    end

    redirect_to project_path(@project), notice: "Group deleted. Its materials are now ungrouped.",
                                        status: :see_other
  rescue ActiveRecord::InvalidForeignKey, ActiveRecord::RecordNotDestroyed
    redirect_to project_path(@project), alert: "This group could not be deleted.",
                                        status: :see_other
  end

  private

  def load_project
    @project = current_user.projects.find(params[:project_id])
    authorize @project, :manage_item_groups?
  end

  def load_item_group
    @item_group = @project.item_groups.find(params[:id])
  end

  def item_group_params
    params.require(:item_group).permit(:title)
  end
end
