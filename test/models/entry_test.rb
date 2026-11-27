require "test_helper"

class EntryTest < ActiveSupport::TestCase
  def setup
    @account = Account.create!(name: "Checking", account_type: :asset, cash_flow_category: :operating)
    @other_account = Account.create!(name: "Checking Transfers", account_type: :asset, cash_flow_category: :operating)
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

  test "project is optional" do
    @entry.project = nil
    assert @entry.valid?
  end

  test "for_project scopes to entries tagged with that project, across any account type" do
    project = Project.create!(name: "Riverside Remodel")
    income_account = Account.create!(name: "Consulting Revenue", account_type: :income, cash_flow_category: :operating)

    tagged = JournalTransaction.create!(date: Date.today, entries_attributes: [
      { account: @account, project: project, entry_type: "debit", amount: 75 },
      { account: income_account, project: project, entry_type: "credit", amount: 75 }
    ])
    JournalTransaction.create!(date: Date.today, entries_attributes: [
      { account: @account, entry_type: "debit", amount: 20 },
      { account: @other_account, entry_type: "credit", amount: 20 }
    ])

    assert_equal tagged.entries.to_set, Entry.for_project(project.id).to_set
  end

  test "profit_and_loss scopes to income/expense entries only" do
    project = Project.create!(name: "Riverside Remodel")
    income_account = Account.create!(name: "Consulting Revenue", account_type: :income, cash_flow_category: :operating)
    expense_account = Account.create!(name: "Materials", account_type: :expense, cash_flow_category: :operating)

    JournalTransaction.create!(date: Date.today, entries_attributes: [
      { account: @account, project: project, entry_type: "debit", amount: 75 },
      { account: income_account, project: project, entry_type: "credit", amount: 75 }
    ])
    JournalTransaction.create!(date: Date.today, entries_attributes: [
      { account: expense_account, project: project, entry_type: "debit", amount: 30 },
      { account: @account, project: project, entry_type: "credit", amount: 30 }
    ])

    pl_accounts = Entry.for_project(project.id).profit_and_loss.map(&:account).to_set
    assert_equal [ income_account, expense_account ].to_set, pl_accounts
  end
end
