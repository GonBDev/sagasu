class CreateGroupSuppliers < ActiveRecord::Migration[8.1]
  def change
    create_table :group_suppliers do |t|
      t.references :item_group, null: false, foreign_key: true, index: false
      t.references :supplier, null: false, foreign_key: true
      t.references :ai_run, foreign_key: true
      t.boolean :ai_suggested, default: false, null: false
      t.text :ai_reason
      t.boolean :selected, default: false, null: false
      t.text :feedback_reason
      t.text :source, null: false

      t.index %i[item_group_id supplier_id], unique: true
      t.timestamps
    end
  end
end
