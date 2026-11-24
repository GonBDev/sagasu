class SetDefaultRoleOnUsers < ActiveRecord::Migration[8.1]
  def change
    change_column_default :users, :role, from: nil, to: "buyer"
    change_column_null :users, :role, false, "buyer"
  end
end
