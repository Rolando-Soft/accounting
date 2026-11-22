require "test_helper"

class AccountsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account = accounts(:one)
    sign_in_as users(:one)
    post switch_workspace_path(@account.workspace)
  end

  test "should get index" do
    get accounts_url
    assert_response :success
  end

  test "should get new" do
    get new_account_url
    assert_response :success
  end

  test "should create account" do
    assert_difference("Account.count") do
      post accounts_url, params: { account: { account_type: @account.account_type, description: @account.description, cash_flow_category: "operating", name: "Revenue" } }
    end

    assert_redirected_to accounts_url
  end

  test "should get edit" do
    get edit_account_url(@account)
    assert_response :success
  end

  test "should update account" do
    patch account_url(@account), params: { account: { account_type: @account.account_type, description: @account.description, name: @account.name } }
    assert_redirected_to accounts_url
  end

  test "should destroy account" do
    assert_difference("Account.count", -1) do
      delete account_url(@account)
    end

    assert_redirected_to accounts_url
  end
end
