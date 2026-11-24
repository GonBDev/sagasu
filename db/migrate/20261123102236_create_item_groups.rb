class CreateItemGroups < ActiveRecord::Migration[8.1]
  def change
    create_table :item_groups do |t|
      t.references :project, null: false, foreign_key: true
      t.text :title, null: false
      t.text :description
      t.text :ai_reason
      t.integer :position

      t.timestamps
    end
  end
end
