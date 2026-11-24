class AiRun < ApplicationRecord
  belongs_to :project
  belongs_to :user
  has_many :group_suppliers

  enum :kind, {
    grouping: "grouping",
    supplier_suggestion: "supplier_suggestion"
  }, validate: true
end
