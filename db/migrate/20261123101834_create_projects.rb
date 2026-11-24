class CreateProjects < ActiveRecord::Migration[8.1]
  def change
    create_table :projects do |t|
      t.references :user, null: false, foreign_key: true
      t.text :title, null: false
      t.text :erp_rfq
      t.text :scope
      t.text :client_name
      t.text :client_area
      t.decimal :budget_amount
      t.text :budget_currency
      t.text :status, default: "draft", null: false
      t.text :buyer_comment

      t.timestamps
    end
  end
end
