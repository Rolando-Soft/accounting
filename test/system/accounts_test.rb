require "application_system_test_case"

class AccountsTest < ApplicationSystemTestCase
  setup do
    @account = accounts(:one)

    # Which workspace ends up current by default (ApplicationController
    # falls back to Workspace.order(:id).first) isn't guaranteed to match
    # the fixture account's workspace, since fixture ids aren't sequential.
    # Removing every other workspace makes the fixture's workspace the only
    # — and therefore the default — one.
    Workspace.where.not(id: @account.workspace_id).destroy_all
  end

  test "visiting the index" do
    visit accounts_url
    assert_selector "h1", text: "Accounts"
  end

  test "should create account" do
    visit accounts_url
    click_on "New account", match: :first

    fill_in "Name", with: "New Test Account"
    select "Asset", from: "Account type"
    fill_in "Description", with: "A new test account"
    select "Operating", from: "Cash flow category"
    click_on "Create Account"

    assert_text "Account was successfully created"
  end

  test "should update Account" do
    visit accounts_url
    find("tr##{dom_id(@account)}").click

    fill_in "Description", with: "An updated description"
    click_on "Update Account"

    assert_text "Account was successfully updated"
  end

  test "should destroy Account" do
    visit accounts_url

    accept_confirm do
      within("tr##{dom_id(@account)}") { click_on "x" }
    end

    assert_text "Account was successfully destroyed"
  end
end
