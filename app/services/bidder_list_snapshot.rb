class BidderListSnapshot
  def self.for_project(project)
    groups = project.item_groups.order(:id).to_a
    selections = GroupSupplier.where(item_group_id: groups.map(&:id), selected: true)
                              .includes(:supplier).order(:id).group_by(&:item_group_id)
    build(project, groups: groups, items: project.items.order(:id), selections: selections)
  end

  def self.build(project, groups:, items:, selections:)
    materials_by_group = items.group_by(&:item_group_id)

    {
      "project" => project.attributes.slice("erp_rfq", "title", "scope"),
      "groups" => groups.map do |group|
        {
          "id" => group.id,
          "title" => group.title,
          "materials" => materials(materials_by_group.fetch(group.id, [])),
          "suppliers" => selections.fetch(group.id, []).map do |entry|
            {
              "id" => entry.supplier_id,
              "name" => entry.supplier.name,
              "source" => entry.source,
              "ai_reason" => entry.ai_reason
            }
          end
        }
      end,
      "ungrouped_materials" => materials(materials_by_group.fetch(nil, []))
    }
  end

  def self.materials(items)
    items.map do |item|
      item.attributes.slice("id", "erp_material", "description", "unit_of_measure")
          .merge("quantity" => item.quantity&.to_s("F"))
    end
  end
  private_class_method :materials
end
