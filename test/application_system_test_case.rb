require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ]

  # System tests drive a real browser, so signing in means visiting and
  # submitting the actual sign-in form rather than posting directly.
  def sign_in_as(user, password: "password")
    visit new_session_url
    fill_in "email_address", with: user.email_address
    fill_in "password", with: password
    click_on "Sign in"
    assert_no_current_path(new_session_path) # waits out the post-login redirect
  end
end
