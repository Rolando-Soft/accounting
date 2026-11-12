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

  test "cash_flow_category enum values" do
    assert_equal 0, Account.cash_flow_categories[:operating]
    assert_equal 1, Account.cash_flow_categories[:investing]
    assert_equal 2, Account.cash_flow_categories[:financing]
  end

  test "valid without a cash_flow_category" do
    account = Account.new(name: "Petty Cash", account_type: :asset)
    assert account.valid?
    assert_nil account.cash_flow_category
  end

  test "valid with a cash_flow_category" do
    account = Account.new(name: "Office Supplies", account_type: :expense, cash_flow_category: :operating)
    assert account.valid?
    assert account.operating?
  end

  test "valid with a parent account of the same type" do
    parent = Account.create!(name: "All Assets", account_type: :asset)
    child = Account.new(name: "Petty Cash", account_type: :asset, parent: parent)
    assert child.valid?
    assert_equal parent, child.parent
    assert_includes parent.children, child
  end

  test "invalid with a parent account of a different type" do
    parent = Account.create!(name: "All Assets", account_type: :asset)
    child = Account.new(name: "Rent Expense", account_type: :expense, parent: parent)
    assert_not child.valid?
    assert_includes child.errors[:account_type], "must match the parent account's type (asset)"
  end

  test "invalid with itself as parent" do
    account = Account.create!(name: "All Assets", account_type: :asset)
    account.parent_id = account.id
    assert_not account.valid?
    assert_includes account.errors[:parent], "can't be the account itself"
  end

  test "invalid with a cycle of parents" do
    grandparent = Account.create!(name: "All Assets", account_type: :asset)
    parent = Account.create!(name: "Bank Accounts", account_type: :asset, parent: grandparent)
    child = Account.create!(name: "Checking", account_type: :asset, parent: parent)

    grandparent.parent = child
    assert_not grandparent.valid?
    assert_includes grandparent.errors[:parent], "cannot create a cycle"
  end

  test "cannot delete account with sub-accounts" do
    parent = Account.create!(name: "All Assets", account_type: :asset)
    Account.create!(name: "Petty Cash", account_type: :asset, parent: parent)

    parent.destroy
    assert_not parent.destroyed?
    assert_includes parent.errors[:base], "Cannot delete account with sub-accounts"
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
