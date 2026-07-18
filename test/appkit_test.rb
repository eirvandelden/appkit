require "test_helper"

class AppkitTest < ActiveSupport::TestCase
  test "version is present" do
    assert Appkit::VERSION
  end

  test "engine is mounted inside the booted dummy app" do
    assert_includes Rails.application.railties.to_a.map(&:class), Appkit::Engine
  end
end
