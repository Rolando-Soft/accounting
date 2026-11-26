require "test_helper"

class ProjectTest < ActiveSupport::TestCase
  test "valid with just a name" do
    project = Project.new(name: "Riverside Remodel")
    assert project.valid?
  end

  test "invalid without a name" do
    project = Project.new
    assert_not project.valid?
    assert_includes project.errors[:name], "can't be blank"
  end

  test "name must be unique within the workspace" do
    Project.create!(name: "Riverside Remodel")
    duplicate = Project.new(name: "Riverside Remodel")
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:name], "has already been taken"
  end

  test "code may be blank but must be unique within the workspace when present" do
    Project.create!(name: "Riverside Remodel", code: "RR-1")
    assert Project.new(name: "Lakeside Build").valid?

    duplicate = Project.new(name: "Lakeside Build", code: "RR-1")
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:code], "has already been taken"
  end

  test "status enum values" do
    assert_equal 0, Project.statuses[:active]
    assert_equal 1, Project.statuses[:archived]
  end

  test "label includes the code when present, otherwise just the name" do
    assert_equal "Riverside Remodel", Project.new(name: "Riverside Remodel").label
    assert_equal "Riverside Remodel (RR-1)", Project.new(name: "Riverside Remodel", code: "RR-1").label
  end

  test "cannot be destroyed while entries reference it" do
    project = Project.create!(name: "Riverside Remodel")
    account = Account.create!(name: "Checking", account_type: :asset, cash_flow_category: :operating)
    other_account = Account.create!(name: "Revenue", account_type: :income, cash_flow_category: :operating)
    JournalTransaction.create!(date: Date.today, entries_attributes: [
      { account: account, project: project, entry_type: "debit", amount: 50 },
      { account: other_account, entry_type: "credit", amount: 50 }
    ])

    assert_not project.destroy
    assert_includes project.errors.full_messages, "Cannot delete record because dependent entries exist"
    assert Project.exists?(project.id)
  end
end
