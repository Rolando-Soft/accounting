class HardenEntries < ActiveRecord::Migration[8.0]
  def change
    change_column_null :entries, :journal_transaction_id, false
    change_column_null :entries, :account_id, false
    change_column_null :entries, :entry_type, false
    change_column :entries, :amount, :decimal, precision: 19, scale: 4, null: false

    add_foreign_key :entries, :journal_transactions, on_delete: :restrict
    add_foreign_key :entries, :accounts, on_delete: :restrict

    add_index :entries, :journal_transaction_id
    add_index :entries, [:account_id, :created_at]

    add_check_constraint :entries, "amount > 0", name: "entries_amount_positive"
    add_check_constraint :entries, "entry_type IN (0, 1)", name: "entries_entry_type_valid"
  end
end
