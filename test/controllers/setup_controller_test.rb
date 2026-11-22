require "test_helper"

class SetupControllerTest < ActionDispatch::IntegrationTest
  test "redirects to sign in when a user already exists" do
    get new_setup_url
    assert_redirected_to new_session_url
  end

  test "refuses to create a second user once one already exists, even via a direct POST" do
    assert_no_difference("User.count") do
      post setup_url, params: { user: { email_address: "attacker@example.com", password: "password", password_confirmation: "password" } }
    end

    assert_redirected_to new_session_url
    assert_equal "Setup has already been completed.", flash[:alert]
  end

  test "creates the first user and signs them in when none exist yet" do
    User.delete_all

    assert_difference("User.count") do
      post setup_url, params: { user: { email_address: "owner@example.com", password: "password", password_confirmation: "password" } }
    end

    assert_redirected_to root_url
    follow_redirect!
    assert_response :success
  end

  test "rejects a mismatched password confirmation" do
    User.delete_all

    assert_no_difference("User.count") do
      post setup_url, params: { user: { email_address: "owner@example.com", password: "password", password_confirmation: "nope" } }
    end

    assert_response :unprocessable_entity
  end

  test "unauthenticated requests go to setup instead of sign in when no user exists" do
    User.delete_all

    get accounts_url
    assert_redirected_to new_setup_url
  end
end
