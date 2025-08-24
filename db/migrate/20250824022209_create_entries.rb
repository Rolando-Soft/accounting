class CreateEntries < ActiveRecord::Migration[8.0]
  def change
    create_table :entries do |t|
      t.bigint :journal_transaction_id
      t.bigint :account_id
      t.decimal :amount
      t.integer :entry_type

      t.timestamps
    end
  end
end
