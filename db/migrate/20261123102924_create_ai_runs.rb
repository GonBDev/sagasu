class CreateAiRuns < ActiveRecord::Migration[8.1]
  def change
    create_table :ai_runs do |t|
      t.references :project, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.text :kind, null: false
      t.text :model
      t.text :prompt
      t.text :output
      t.text :status

      t.timestamps
    end
  end
end
