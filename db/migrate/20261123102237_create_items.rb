class CreateItems < ActiveRecord::Migration[8.1]
  def change
    create_table :items do |t|
      t.references :project, null: false, foreign_key: true
      t.references :item_group, foreign_key: true
      t.text :erp_material
      t.text :description
      t.decimal :quantity
      t.text :unit_of_measure

      t.timestamps
    end
  end
end
