require "test_helper"

class AccountTest < ActiveSupport::TestCase
  # test/models/account_test.rb
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
      account = Account.new(name: "Cash", account_type: :asset)
      assert account.valid?
    end

    test "invalid without name" do
      account = Account.new(account_type: :asset)
      assert_not account.valid?
      assert_includes account.errors[:name], "can't be blank"
    end

    test "invalid without account_type" do
      account = Account.new(name: "Cash")
      assert_not account.valid?
      assert_includes account.errors[:account_type], "can't be blank"
    end
  end
end
