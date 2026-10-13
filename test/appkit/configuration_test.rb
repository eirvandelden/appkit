require "test_helper"

module Appkit
  class ConfigurationTest < ActiveSupport::TestCase
    test "health_check_path defaults to healthz, avoiding a collision with Rails' own /up check" do
      assert_equal "healthz", Configuration.new.health_check_path
    end

    test "app_display_name resolves the configured app_name" do
      configuration = Configuration.new
      configuration.app_name = "My App"

      assert_equal "My App", configuration.app_display_name
    end

    test "app_name keeps returning a callable unchanged" do
      callable = -> { "My App" }
      configuration = Configuration.new
      configuration.app_name = callable

      assert_same callable, configuration.app_name
      assert_equal "My App", configuration.app_display_name
    end
  end
end
