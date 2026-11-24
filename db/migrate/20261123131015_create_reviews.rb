class CreateReviews < ActiveRecord::Migration[8.1]
  def change
    create_table :reviews do |t|
      t.references :user, null: false, foreign_key: true
      t.references :supplier, null: false, foreign_key: true
      t.references :project, foreign_key: true
      t.integer :rating
      t.text :comment
      t.text :visibility, default: "organization", null: false
      t.boolean :ai_usable, default: true, null: false
      t.text :status, default: "unverified", null: false

      t.timestamps
    end
  end
end
