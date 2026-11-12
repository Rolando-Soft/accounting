require "test_helper"

class EntryTest < ActiveSupport::TestCase
  def setup
    @account = Account.create!(name: "Checking", account_type: :asset)
    @other_account = Account.create!(name: "Checking Transfers", account_type: :asset)
    @journal_transaction = JournalTransaction.create!(date: Date.today, entries_attributes: [
      { account: @account, entry_type: "debit", amount: 50 },
      { account: @other_account, entry_type: "credit", amount: 50 }
    ])
    @entry = Entry.new(
      account: @account,
      journal_transaction: @journal_transaction,
      amount: 100,
      entry_type: "debit"
    )
  end

  test "should be valid with valid attributes" do
    assert @entry.valid?
  end

  test "should require account" do
    @entry.account = nil
    assert_not @entry.valid?
  end

  test "should require journal_transaction" do
    @entry.journal_transaction = nil
    assert_not @entry.valid?
  end

  test "should require amount greater than 0" do
    @entry.amount = 0
    assert_not @entry.valid?
    @entry.amount = -10
    assert_not @entry.valid?
  end

  test "should accept valid entry_type" do
    @entry.entry_type = "credit"
    assert @entry.valid?
  end

  test "should not accept invalid entry_type" do
    assert_raises ArgumentError do
      @entry.entry_type = "invalid"
    end
  end
end
