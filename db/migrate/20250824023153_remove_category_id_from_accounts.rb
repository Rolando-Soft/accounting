class RemoveCategoryIdFromAccounts < ActiveRecord::Migration[8.0]
  def change
    remove_column :accounts, :category_id, :integer
  end
end
