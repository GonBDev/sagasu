class Project < ApplicationRecord
  BUDGET_CURRENCIES = %w[JPY USD EUR MXN PEN CFP].freeze

  belongs_to :user
  has_many :item_groups
  has_many :items
  has_many :bidder_list_versions

  enum :status, {
    draft: "draft",
    pending_approval: "pending_approval",
    approved: "approved",
    returned: "returned"
  }, validate: true

  validates :title, presence: true
  has_many :approvals
  has_many :reviews
end
