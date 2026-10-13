require "test_helper"

class AppkitTest < ActiveSupport::TestCase
  test "version names the checked-out commit" do
    sha = `git -C #{Appkit::Engine.root} rev-parse --short HEAD`.strip

    assert_equal "#{Appkit::BASE_VERSION}.pre.git.#{sha}", Appkit::VERSION
  end

  test "engine is mounted inside the booted dummy app" do
    assert_includes Rails.application.railties.to_a.map(&:class), Appkit::Engine
  end
end
