ENV["RAILS_ENV"] ||= "test"

require "bcrypt"
require_relative "dummy/config/environment"
require "rails/test_help"

load Rails.root.join("db/schema.rb")

ActiveSupport::TestCase.fixture_paths = [ File.expand_path("fixtures", __dir__) ]
ActiveSupport::TestCase.fixtures :all

# The sessions#create rate limiter uses Rails.cache, which otherwise leaks
# attempt counts across test cases sharing the same process/IP.
ActiveSupport::TestCase.setup { Rails.cache.clear }

class ActionDispatch::IntegrationTest
  def sign_in_as(user)
    post session_url, params: { email_address: user.email, password: "password" }
  end
end
