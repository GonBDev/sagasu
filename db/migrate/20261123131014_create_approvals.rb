class CreateApprovals < ActiveRecord::Migration[8.1]
  def change
    create_table :approvals do |t|
      t.references :project, null: false, foreign_key: true
      t.references :approver, null: false, foreign_key: { to_table: :users }
      t.text :status, default: "pending", null: false
      t.text :comment
      t.datetime :decided_at
      t.jsonb :snapshot

      t.timestamps
    end
  end
end
