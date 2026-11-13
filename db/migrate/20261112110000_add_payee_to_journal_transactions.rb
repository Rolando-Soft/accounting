class AddPayeeToJournalTransactions < ActiveRecord::Migration[8.0]
  def change
    add_column :journal_transactions, :payee, :string
    add_index :journal_transactions, :payee
  end
end
