class AddCashFlowCategoryToAccounts < ActiveRecord::Migration[8.0]
  def change
    add_column :accounts, :cash_flow_category, :integer
  end
end
