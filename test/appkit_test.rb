require "test_helper"

class AppkitTest < ActiveSupport::TestCase
  test "version names the checked-out commit" do
    sha = IO.popen([ "git", "-C", Appkit::Engine.root.to_s, "rev-parse", "--short", "HEAD" ], &:read).strip

    assert_equal "#{Appkit::BASE_VERSION}.pre.git.#{sha}", Appkit::VERSION
  end

  test "engine is mounted inside the booted dummy app" do
    assert_includes Rails.application.railties.to_a.map(&:class), Appkit::Engine
  end
end
