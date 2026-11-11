require "test_helper"

class AccountTest < ActiveSupport::TestCase
  test "account_type enum values" do
    assert_equal 0, Account.account_types[:asset]
    assert_equal 1, Account.account_types[:liability]
    assert_equal 2, Account.account_types[:income]
    assert_equal 3, Account.account_types[:expense]
    assert_equal 4, Account.account_types[:equity]
  end

  test "valid with name and account_type" do
    account = Account.new(name: "Petty Cash", account_type: :asset)
    assert account.valid?
  end

  test "invalid without name" do
    account = Account.new(account_type: :asset)
    assert_not account.valid?
    assert_includes account.errors[:name], "can't be blank"
  end

  test "invalid without account_type" do
    account = Account.new(name: "Petty Cash")
    assert_not account.valid?
    assert_includes account.errors[:account_type], "can't be blank"
  end

  test "cannot delete account with associated journal transactions" do
    account = Account.create!(name: "Bank", account_type: :asset)
    exp_account = Account.create!(name: "Expense", account_type: :expense)
    JournalTransaction.create!(date: Date.today, description: "test", entries_attributes: [
      { account: account, amount: 100.00, entry_type: "debit" },
      { account: exp_account, amount: 100.00, entry_type: "credit" }
    ])

    account.destroy
    assert_not account.destroyed?
    assert_includes account.errors[:base], "Cannot delete account with associated journal transactions"
  end
end
