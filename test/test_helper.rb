ENV["RAILS_ENV"] ||= "test"

require "bcrypt"
require_relative "dummy/config/environment"
require "rails/test_help"

load Rails.root.join("db/schema.rb")

ActiveSupport::TestCase.fixture_paths = [File.expand_path("fixtures", __dir__)]
ActiveSupport::TestCase.fixtures :all
