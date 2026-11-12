class AddReconciliationStatusToEntries < ActiveRecord::Migration[8.0]
  def change
    add_column :entries, :reconciliation_status, :integer, default: 0, null: false
    add_index :entries, :reconciliation_status
  end
end
