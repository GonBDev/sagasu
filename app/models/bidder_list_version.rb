class BidderListVersion < ApplicationRecord
  belongs_to :project
  belongs_to :created_by, class_name: "User"

  attr_readonly :project_id, :created_by_id, :version_number, :snapshot, :change_reason, :created_at
end
