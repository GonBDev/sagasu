class GroupSupplier < ApplicationRecord
  belongs_to :item_group
  belongs_to :supplier
  belongs_to :ai_run, optional: true

  enum :source, { ai: "ai", search: "search" }, validate: true

  validates :supplier_id, uniqueness: { scope: :item_group_id }
  validate :ai_run_belongs_to_same_project

  private

  def ai_run_belongs_to_same_project
    return if ai_run.nil? || item_group.nil?
    return if ai_run.project == item_group.project

    errors.add(:ai_run, "must belong to the same project as the item group")
  end
end
