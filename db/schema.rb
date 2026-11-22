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

ActiveRecord::Schema[8.0].define(version: 2026_11_22_170605) do
  create_table "accounts", force: :cascade do |t|
    t.string "name"
    t.integer "account_type"
    t.string "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "cash_flow_category"
    t.integer "parent_id"
    t.integer "workspace_id", null: false
    t.boolean "primary", default: false, null: false
    t.index ["parent_id"], name: "index_accounts_on_parent_id"
    t.index ["workspace_id"], name: "index_accounts_on_workspace_id"
  end

  create_table "entries", force: :cascade do |t|
    t.bigint "journal_transaction_id", null: false
    t.bigint "account_id", null: false
    t.decimal "amount", precision: 19, scale: 4, null: false
    t.integer "entry_type", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "reconciliation_status", default: 0, null: false
    t.string "description"
    t.index ["account_id", "created_at"], name: "index_entries_on_account_id_and_created_at"
    t.index ["journal_transaction_id"], name: "index_entries_on_journal_transaction_id"
    t.index ["reconciliation_status"], name: "index_entries_on_reconciliation_status"
    t.check_constraint "amount > 0", name: "entries_amount_positive"
    t.check_constraint "entry_type IN (0, 1)", name: "entries_entry_type_valid"
  end

  create_table "journal_transactions", force: :cascade do |t|
    t.date "date"
    t.string "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "payee"
    t.integer "workspace_id", null: false
    t.index ["payee"], name: "index_journal_transactions_on_payee"
    t.index ["workspace_id"], name: "index_journal_transactions_on_workspace_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  create_table "workspaces", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_workspaces_on_name", unique: true
  end

  add_foreign_key "accounts", "accounts", column: "parent_id"
  add_foreign_key "accounts", "workspaces"
  add_foreign_key "entries", "accounts", on_delete: :restrict
  add_foreign_key "entries", "journal_transactions", on_delete: :restrict
  add_foreign_key "journal_transactions", "workspaces"
  add_foreign_key "sessions", "users"
end
