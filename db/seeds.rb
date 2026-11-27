# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

Current.workspace = Workspace.find_or_create_by!(name: "Personal")

cash = Account.create!(name: "Cash", account_type: :asset, description: "Cash account")
groceries = Account.create!(name: "Groceries", account_type: :expense, description: "Grocery expenses")
salary = Account.create!(name: "Salary", account_type: :income, description: "Salary income")
rent = Account.create!(name: "Rent", account_type: :expense, description: "Rent expenses")

salary_tx = JournalTransaction.create!(date: Date.today, description: "Monthly Salary")
salary_tx.entries.create!(account: cash, entry_type: :debit, amount: 2000)
salary_tx.entries.create!(account: salary, entry_type: :credit, amount: 2000)

rent_tx = JournalTransaction.create!(date: Date.today, description: "Monthly Rent")
rent_tx.entries.create!(account: rent, entry_type: :debit, amount: 1000)
rent_tx.entries.create!(account: cash, entry_type: :credit, amount: 1000)

groceries_tx = JournalTransaction.create!(date: Date.today, description: "Grocery Shopping")
groceries_tx.entries.create!(account: groceries, entry_type: :debit, amount: 200)
groceries_tx.entries.create!(account: cash, entry_type: :credit, amount: 200)
