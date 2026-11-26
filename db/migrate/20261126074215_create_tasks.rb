class CreateTasks < ActiveRecord::Migration[8.1]
  def change
    create_table :tasks do |t|
      t.references :assignee, null: false, foreign_key: { to_table: :users }
      t.references :actionable, polymorphic: true, null: false, index: false
      t.string :kind, null: false

      t.timestamps
      t.index %i[actionable_type actionable_id kind], unique: true
    end
  end
end
