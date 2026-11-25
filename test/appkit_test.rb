require "test_helper"

class AppkitTest < ActiveSupport::TestCase
  test "version is a plain semver number" do
    assert_match(/\A\d+\.\d+\.\d+\z/, Appkit::VERSION)
  end

  test "engine is mounted inside the booted dummy app" do
    assert_includes Rails.application.railties.to_a.map(&:class), Appkit::Engine
  end
end
