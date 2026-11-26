class LinkApprovalsToBidderListVersions < ActiveRecord::Migration[8.1]
  def change
    add_reference :approvals, :bidder_list_version, foreign_key: true
    add_index :approvals, :project_id, unique: true,
              where: "status = 'pending' AND bidder_list_version_id IS NOT NULL",
              name: "index_approvals_on_one_pending_version_per_project"
  end
end
