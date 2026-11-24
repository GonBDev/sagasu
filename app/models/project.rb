class Project < ApplicationRecord
  belongs_to :user
  has_many :item_groups
  has_many :items

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
