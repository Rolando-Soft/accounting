class AddPrimaryToAccounts < ActiveRecord::Migration[8.0]
  def change
    add_column :accounts, :primary, :boolean, default: false, null: false
  end
end
