class CreateAccounts < ActiveRecord::Migration[8.0]
  def change
    create_table :accounts do |t|
      t.string :name
      t.integer :account_type
      t.string :description
      t.integer :category_id

      t.timestamps
    end
  end
end
