# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_11_26_074216) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "ai_runs", force: :cascade do |t|
    t.bigint "project_id", null: false
    t.bigint "user_id", null: false
    t.text "kind", null: false
    t.text "model"
    t.text "prompt"
    t.text "output"
    t.text "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id"], name: "index_ai_runs_on_project_id"
    t.index ["user_id"], name: "index_ai_runs_on_user_id"
  end

  create_table "approvals", force: :cascade do |t|
    t.bigint "project_id", null: false
    t.bigint "approver_id", null: false
    t.text "status", default: "pending", null: false
    t.text "comment"
    t.datetime "decided_at"
    t.jsonb "snapshot"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "bidder_list_version_id"
    t.index ["approver_id"], name: "index_approvals_on_approver_id"
    t.index ["bidder_list_version_id"], name: "index_approvals_on_bidder_list_version_id"
    t.index ["project_id"], name: "index_approvals_on_one_pending_version_per_project", unique: true, where: "((status = 'pending'::text) AND (bidder_list_version_id IS NOT NULL))"
    t.index ["project_id"], name: "index_approvals_on_project_id"
  end

  create_table "bidder_list_versions", force: :cascade do |t|
    t.bigint "project_id", null: false
    t.bigint "created_by_id", null: false
    t.integer "version_number", null: false
    t.jsonb "snapshot", null: false
    t.text "change_reason"
    t.datetime "created_at", null: false
    t.index ["created_by_id"], name: "index_bidder_list_versions_on_created_by_id"
    t.index ["project_id", "version_number"], name: "index_bidder_list_versions_on_project_id_and_version_number", unique: true
    t.check_constraint "version_number > 0", name: "bidder_list_versions_positive_number"
  end

  create_table "chats", force: :cascade do |t|
    t.bigint "participant_one_id", null: false
    t.bigint "participant_two_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["participant_one_id", "participant_two_id"], name: "index_chats_on_participant_one_id_and_participant_two_id", unique: true
    t.index ["participant_two_id"], name: "index_chats_on_participant_two_id"
    t.check_constraint "participant_one_id <= participant_two_id", name: "chats_ordered_participants"
  end

  create_table "group_suppliers", force: :cascade do |t|
    t.bigint "item_group_id", null: false
    t.bigint "supplier_id", null: false
    t.bigint "ai_run_id"
    t.boolean "ai_suggested", default: false, null: false
    t.text "ai_reason"
    t.boolean "selected", default: false, null: false
    t.text "feedback_reason"
    t.text "source", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ai_run_id"], name: "index_group_suppliers_on_ai_run_id"
    t.index ["item_group_id", "supplier_id"], name: "index_group_suppliers_on_item_group_id_and_supplier_id", unique: true
    t.index ["supplier_id"], name: "index_group_suppliers_on_supplier_id"
  end

  create_table "item_groups", force: :cascade do |t|
    t.bigint "project_id", null: false
    t.text "title", null: false
    t.text "description"
    t.text "ai_reason"
    t.integer "position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id"], name: "index_item_groups_on_project_id"
  end

  create_table "items", force: :cascade do |t|
    t.bigint "project_id", null: false
    t.bigint "item_group_id"
    t.text "erp_material"
    t.text "description"
    t.decimal "quantity"
    t.text "unit_of_measure"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["item_group_id"], name: "index_items_on_item_group_id"
    t.index ["project_id"], name: "index_items_on_project_id"
  end

  create_table "messages", force: :cascade do |t|
    t.bigint "chat_id", null: false
    t.bigint "sender_id", null: false
    t.text "content", null: false
    t.datetime "read_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "task_id"
    t.index ["chat_id"], name: "index_messages_on_chat_id"
    t.index ["sender_id"], name: "index_messages_on_sender_id"
    t.index ["task_id"], name: "index_messages_on_task_id", unique: true
  end

  create_table "projects", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.text "title", null: false
    t.text "erp_rfq"
    t.text "scope"
    t.text "client_name"
    t.text "client_area"
    t.decimal "budget_amount"
    t.text "budget_currency"
    t.text "status", default: "draft", null: false
    t.text "buyer_comment"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_projects_on_user_id"
  end

  create_table "reviews", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "supplier_id", null: false
    t.bigint "project_id"
    t.integer "rating"
    t.text "comment"
    t.text "visibility", default: "organization", null: false
    t.boolean "ai_usable", default: true, null: false
    t.text "status", default: "unverified", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id"], name: "index_reviews_on_project_id"
    t.index ["supplier_id"], name: "index_reviews_on_supplier_id"
    t.index ["user_id"], name: "index_reviews_on_user_id"
  end

  create_table "suppliers", force: :cascade do |t|
    t.string "name", null: false
    t.string "primary_email"
    t.string "erp_vendor_id"
    t.string "sm_vendor_id"
    t.string "source_system"
    t.string "country_code"
    t.string "state_name"
    t.string "city"
    t.string "tax_id"
    t.string "tax_id_type_code"
    t.boolean "active"
    t.string "category"
    t.text "business_activity"
    t.text "description"
    t.string "website"
    t.text "ai_comments"
    t.string "tags", default: [], null: false, array: true
    t.string "size"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["erp_vendor_id"], name: "index_suppliers_on_erp_vendor_id", unique: true
  end

  create_table "tasks", force: :cascade do |t|
    t.bigint "assignee_id", null: false
    t.string "actionable_type", null: false
    t.bigint "actionable_id", null: false
    t.string "kind", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["actionable_type", "actionable_id", "kind"], name: "index_tasks_on_actionable_type_and_actionable_id_and_kind", unique: true
    t.index ["assignee_id"], name: "index_tasks_on_assignee_id"
  end

  create_table "user_roles", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "role", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "role"], name: "index_user_roles_on_user_id_and_role", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "name"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "ai_runs", "projects"
  add_foreign_key "ai_runs", "users"
  add_foreign_key "approvals", "bidder_list_versions"
  add_foreign_key "approvals", "projects"
  add_foreign_key "approvals", "users", column: "approver_id"
  add_foreign_key "bidder_list_versions", "projects"
  add_foreign_key "bidder_list_versions", "users", column: "created_by_id"
  add_foreign_key "chats", "users", column: "participant_one_id"
  add_foreign_key "chats", "users", column: "participant_two_id"
  add_foreign_key "group_suppliers", "ai_runs"
  add_foreign_key "group_suppliers", "item_groups"
  add_foreign_key "group_suppliers", "suppliers"
  add_foreign_key "item_groups", "projects"
  add_foreign_key "items", "item_groups"
  add_foreign_key "items", "projects"
  add_foreign_key "messages", "chats"
  add_foreign_key "messages", "tasks"
  add_foreign_key "messages", "users", column: "sender_id"
  add_foreign_key "projects", "users"
  add_foreign_key "reviews", "projects"
  add_foreign_key "reviews", "suppliers"
  add_foreign_key "reviews", "users"
  add_foreign_key "tasks", "users", column: "assignee_id"
  add_foreign_key "user_roles", "users"
end
