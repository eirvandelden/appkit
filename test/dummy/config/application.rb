require_relative "boot"

require "rails"
require "active_record/railtie"
require "active_job/railtie"
require "action_controller/railtie"
require "action_view/railtie"
require "propshaft"
require "importmap-rails"
require "turbo-rails"
require "solid_queue"
require "solid_cache"

require "appkit"

module Dummy
  class Application < Rails::Application
    config.root = File.expand_path("..", __dir__)
    config.load_defaults Rails::VERSION::STRING.to_f
    config.eager_load = false
    config.app_version = "1.2.3"
    config.git_revision = "deadbeef"
  end
end
