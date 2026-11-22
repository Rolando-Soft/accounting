ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Model tests create records directly (no request/controller involved),
    # so they need an explicit Current.workspace; request/controller tests
    # overwrite this via ApplicationController's own before_action anyway.
    setup { Current.workspace = workspaces(:one) }
    teardown { Current.reset }

    # Add more helper methods to be used by all tests here...
  end
end

module SignInHelper
  # For ActionDispatch::IntegrationTest — posts straight to the sessions
  # controller rather than driving a browser. All fixture users share the
  # "password" password set in test/fixtures/users.yml.
  def sign_in_as(user, password: "password")
    post session_url, params: { email_address: user.email_address, password: password }
  end
end

ActionDispatch::IntegrationTest.include SignInHelper
