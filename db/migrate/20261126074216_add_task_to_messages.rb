class AddTaskToMessages < ActiveRecord::Migration[8.1]
  def change
    add_reference :messages, :task, foreign_key: true, index: { unique: true }
  end
end
