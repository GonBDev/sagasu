class Item < ApplicationRecord
  belongs_to :project
  belongs_to :item_group, optional: true

  validate :item_group_belongs_to_project

  validates :description, :unit_of_measure, presence: true
  validates :quantity, numericality: { greater_than: 0 }

  private

  def item_group_belongs_to_project
    return if item_group.nil? || item_group.project == project

    errors.add(:item_group, "must belong to the same project")
  end
end
