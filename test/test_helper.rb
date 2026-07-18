ENV["RAILS_ENV"] ||= "test"

require "bcrypt"
require_relative "dummy/config/environment"
require "rails/test_help"

load Rails.root.join("db/schema.rb")

ActiveSupport::TestCase.fixture_paths = [File.expand_path("fixtures", __dir__)]
ActiveSupport::TestCase.fixtures :all

# The sessions#create rate limiter uses Rails.cache, which otherwise leaks
# attempt counts across test cases sharing the same process/IP.
ActiveSupport::TestCase.setup { Rails.cache.clear }

class ActionDispatch::IntegrationTest
  # The engine is non-isolated: its route helpers (session_path, etc.) are
  # mixed into ActionController::Base/ActionView for real requests (see
  # Appkit::Engine's "appkit.url_helpers" initializer), but integration tests
  # generate URLs through the main app's route set directly, so they need the
  # same mixin here too.
  include Appkit::Engine.routes.url_helpers

  def sign_in_as(user)
    post session_url, params: { email_address: user.email, password: "password" }
  end
end
