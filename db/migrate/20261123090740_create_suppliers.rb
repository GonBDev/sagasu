class CreateSuppliers < ActiveRecord::Migration[8.1]
  def change
    create_table :suppliers do |t|
      t.string :name, null: false
      t.string :primary_email
      t.string :erp_vendor_id
      t.index :erp_vendor_id, unique: true
      t.string :sm_vendor_id
      t.string :source_system
      t.string :country_code
      t.string :state_name
      t.string :city
      t.string :tax_id
      t.string :tax_id_type_code
      t.boolean :active
      t.string :category
      t.text :business_activity
      t.text :description
      t.string :website
      t.text :ai_comments
      t.string :tags, array: true, default: [], null: false
      t.string :size

      t.timestamps
    end
  end
end
