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
