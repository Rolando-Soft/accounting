class RemovePrimaryFromAccounts < ActiveRecord::Migration[8.0]
  def change
    remove_column :accounts, :primary, :boolean, default: false, null: false
  end
end
