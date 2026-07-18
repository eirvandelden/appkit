require "test_helper"

module Appkit
  class ConfigurationTest < ActiveSupport::TestCase
    test "health_check_path defaults to healthz, avoiding a collision with Rails' own /up check" do
      assert_equal "healthz", Configuration.new.health_check_path
    end
  end
end
