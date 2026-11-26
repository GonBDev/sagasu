class CreateBidderListVersions < ActiveRecord::Migration[8.1]
  def change
    create_table :bidder_list_versions do |t|
      t.references :project, null: false, foreign_key: true, index: false
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.integer :version_number, null: false
      t.jsonb :snapshot, null: false
      t.text :change_reason
      t.datetime :created_at, null: false

      t.index %i[project_id version_number], unique: true
      t.check_constraint "version_number > 0", name: "bidder_list_versions_positive_number"
    end
  end
end
