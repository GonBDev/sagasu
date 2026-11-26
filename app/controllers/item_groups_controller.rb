class ItemGroupsController < ApplicationController
  after_action :verify_authorized

  before_action :load_project
  before_action :load_item_group, only: %i[update destroy suggest_suppliers shortlist_supplier]

  def shortlist_supplier
    selected = params[:selected]
    return head :bad_request unless %w[true false].include?(selected)

    @project.with_lock do
      authorize @project, :manage_item_groups?
      @item_group.lock!
      if selected == "true"
        supplier = Supplier.where(active: true).lock.find(params[:supplier_id])
        candidate = GroupSupplier.find_or_initialize_by(item_group: @item_group, supplier: supplier)
        candidate.source = :search if candidate.new_record?
        candidate.update!(selected: true)
      else
        candidate = GroupSupplier.find_by!(item_group: @item_group, supplier_id: params[:supplier_id])
        candidate.update!(selected: false)
      end
    end

    notice = selected == "true" ? "Supplier added to the draft bidder list." : "Supplier removed from the draft bidder list."
    search_query = params[:q].to_s.strip
    search_options = search_query.present? ? { supplier_group_id: @item_group.id, q: search_query } : {}
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.refresh(request_id: nil, method: :morph, scroll: :preserve) }
      format.html { redirect_to bidder_list_suppliers_project_path(@project, **search_options), notice: notice, status: :see_other }
    end
  end

  def suggest_suppliers
    result = SupplierSuggester.new(@item_group).call
    suggestions = result.fetch(:suggestions)

    @project.with_lock do
      authorize @project, :manage_item_groups?
      @item_group.lock!
      supplier_ids = suggestions.map { |suggestion| suggestion.fetch("supplier_id") }
      active_ids = Supplier.where(id: supplier_ids, active: true).order(:id).lock.pluck(:id)
      unless active_ids == supplier_ids.sort
        raise SupplierSuggester::InvalidSuggestions, "The supplier directory changed. Generate suggestions again."
      end

      run = AiRun.create!(
        project: @project, user: current_user, kind: :supplier_suggestion, model: result.fetch(:model),
        prompt: SupplierSuggester::INSTRUCTIONS, output: JSON.generate(suggestions), status: "completed"
      )

      suggestions.each do |suggestion|
        candidate = GroupSupplier.find_or_initialize_by(
          item_group: @item_group, supplier_id: suggestion.fetch("supplier_id")
        )
        candidate.source = :ai if candidate.new_record?
        candidate.update!(ai_run: run, ai_suggested: true, ai_reason: suggestion.fetch("reason"))
      end
    end

    notice = suggestions.empty? ? "No supported supplier matches were found." : "Supplier suggestions generated."
    redirect_to bidder_list_suppliers_project_path(@project), notice: notice, status: :see_other
  rescue SupplierSuggester::NoMaterials, SupplierSuggester::NoCandidates, SupplierSuggester::InvalidSuggestions => error
    redirect_to bidder_list_suppliers_project_path(@project), alert: error.message, status: :see_other
  rescue RubyLLM::Error, Faraday::Error, ActiveRecord::RecordInvalid
    redirect_to bidder_list_suppliers_project_path(@project),
                alert: "Could not generate supplier suggestions. Please try again.", status: :see_other
  end

  def propose
    proposal = ItemGrouper.new(@project).call
    run = AiRun.create!(
      project: @project,
      user: current_user,
      kind: :grouping,
      model: proposal.fetch(:model),
      prompt: ItemGrouper::INSTRUCTIONS,
      output: JSON.generate(proposal.fetch(:groups)),
      status: "completed"
    )
    redirect_to bidder_list_groups_project_path(@project, proposal_id: run.id), status: :see_other
  rescue ItemGrouper::NoMaterials, ItemGrouper::InvalidProposal => error
    redirect_to bidder_list_groups_project_path(@project), alert: error.message, status: :see_other
  rescue RubyLLM::Error, Faraday::Error
    redirect_to bidder_list_groups_project_path(@project), alert: "Could not generate groups. Please try again.", status: :see_other
  end

  def apply_proposal
    @project.with_lock do
      authorize @project, :manage_item_groups?
      run = AiRun.grouping.lock.find_by!(id: params[:proposal_id], project: @project, user: current_user)
      unless run.status == "completed"
        raise ItemGrouper::InvalidProposal, "This proposal is no longer available."
      end

      groups = JSON.parse(run.output)
      item_ids = groups.flat_map { |group| group.fetch("item_ids") }
      items = @project.items.where(id: item_ids, item_group_id: nil).order(:id).lock.index_by(&:id)
      unless items.keys.sort == item_ids.sort
        raise ItemGrouper::InvalidProposal, "The materials changed. Generate a new proposal."
      end

      groups.each do |proposal|
        group = @project.item_groups.create!(title: proposal.fetch("title"))
        proposal.fetch("item_ids").each { |id| items.fetch(id).update!(item_group: group) }
      end
      run.update!(status: "applied")
    end

    redirect_to bidder_list_groups_project_path(@project), notice: "Suggested groups applied.", status: :see_other
  rescue ItemGrouper::InvalidProposal => error
    redirect_to bidder_list_groups_project_path(@project), alert: error.message, status: :see_other
  rescue ActiveRecord::RecordInvalid
    redirect_to bidder_list_groups_project_path(@project), alert: "Could not apply the suggested groups.", status: :see_other
  end

  def create
    @item_group = @project.item_groups.build(item_group_params)

    if @item_group.save
      redirect_to bidder_list_groups_project_path(@project), notice: "Group created.", status: :see_other
    else
      redirect_to bidder_list_groups_project_path(@project), alert: @item_group.errors.full_messages.to_sentence,
                                          status: :see_other
    end
  end

  def update
    if @item_group.update(item_group_params)
      redirect_to bidder_list_groups_project_path(@project), notice: "Group renamed.", status: :see_other
    else
      redirect_to bidder_list_groups_project_path(@project), alert: @item_group.errors.full_messages.to_sentence,
                                          status: :see_other
    end
  end

  def destroy
    ItemGroup.transaction do
      @item_group.items.update_all(item_group_id: nil, updated_at: Time.current)
      @item_group.destroy!
    end

    redirect_to bidder_list_groups_project_path(@project), notice: "Group deleted. Its materials are now ungrouped.",
                                        status: :see_other
  rescue ActiveRecord::InvalidForeignKey, ActiveRecord::RecordNotDestroyed
    redirect_to bidder_list_groups_project_path(@project), alert: "This group could not be deleted.",
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
