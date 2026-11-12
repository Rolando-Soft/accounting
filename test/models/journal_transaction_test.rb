require "test_helper"

class JournalTransactionTest < ActiveSupport::TestCase
  def setup
    @account = Account.create!(name: "Savings", account_type: :asset)
  end

  test "is valid with balanced entries" do
    jt = JournalTransaction.new(date: Date.today)
    jt.entries.build(account: @account, entry_type: :debit, amount: 100)
    jt.entries.build(account: @account, entry_type: :credit, amount: 100)
    assert jt.valid?
  end

  test "is invalid with unbalanced entries" do
    jt = JournalTransaction.new(date: Date.today)
    jt.entries.build(account: @account, entry_type: :debit, amount: 100)
    jt.entries.build(account: @account, entry_type: :credit, amount: 50)
    assert_not jt.valid?
    assert_match /Transaction is not balanced/, jt.errors[:base].first
  end

  test "is invalid with no entries" do
    jt = JournalTransaction.new(date: Date.today)
    assert_not jt.valid?
    assert_includes jt.errors[:base], "Transaction must have at least two entries"
  end

  test "is invalid with only one entry" do
    jt = JournalTransaction.new(date: Date.today)
    jt.entries.build(account: @account, entry_type: :debit, amount: 100)
    assert_not jt.valid?
    assert_includes jt.errors[:base], "Transaction must have at least two entries"
  end

  test "is invalid without a date" do
    jt = JournalTransaction.new
    assert_not jt.valid?
    assert_includes jt.errors[:date], "can't be blank"
  end
end
