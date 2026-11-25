class CreateUserRoles < ActiveRecord::Migration[8.1]
  def up # Create the table and backfill existing accounts together.
    create_table :user_roles do |t|
      t.references :user, null: false, foreign_key: true, index: false # Use the composite index for user lookups.
      t.string :role, null: false # Require a role for every assignment.

      t.timestamps
      t.index %i[user_id role], unique: true # Prevent duplicate grants to the same user.
    end

    # Give all existing accounts BASE and preserve buyer and approver grants.
    execute <<~SQL # Backfill directly from the legacy users table.
      INSERT INTO user_roles (user_id, role, created_at, updated_at)
      SELECT id, 'base', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM users
      UNION ALL
      SELECT id, role, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM users
      WHERE role IN ('buyer', 'approver')
    SQL
  end # Finish the migration.

  def down # Reverse the table creation.
    drop_table :user_roles # Remove the generated role assignments.
  end
end
