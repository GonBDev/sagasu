class RemoveRoleFromUsers < ActiveRecord::Migration[8.1]
  def change
    remove_column :users, :role, :text, default: "buyer", null: false # Preserve the legacy column definition on rollback.
  end
end
