class Review < ApplicationRecord
  belongs_to :user
  belongs_to :supplier
  belongs_to :project, optional: true

  enum :visibility, {
    organization: "organization",
    project: "project"
  }, prefix: true, validate: true

  enum :status, {
    unverified: "unverified",
    verified: "verified",
    disputed: "disputed"
  }, validate: true

  validates :project, presence: true, if: :visibility_project?
end
