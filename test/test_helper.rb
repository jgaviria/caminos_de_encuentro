ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "factory_bot_rails"
require "mocha/minitest"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    # fixtures :all # Disabled in favor of FactoryBot
    
    # Include FactoryBot methods
    include FactoryBot::Syntax::Methods

    # Add more helper methods to be used by all tests here...
    
    # Helper method to sign in a user for controller tests
    def sign_in(user)
      @request.env["devise.mapping"] = Devise.mappings[:user]
      sign_in user
    end
  end
end
