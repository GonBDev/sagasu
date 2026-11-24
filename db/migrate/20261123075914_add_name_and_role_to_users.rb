class AddNameAndRoleToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :name, :text
    add_column :users, :role, :text
  end
end
