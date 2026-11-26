class CreateChats < ActiveRecord::Migration[8.1]
  def change
    create_table :chats do |t|
      t.references :participant_one, null: false, foreign_key: { to_table: :users }, index: false
      t.references :participant_two, null: false, foreign_key: { to_table: :users }
      t.timestamps

      t.index %i[participant_one_id participant_two_id], unique: true
      t.check_constraint "participant_one_id <= participant_two_id", name: "chats_ordered_participants"
    end
  end
end
