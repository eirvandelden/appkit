require "test_helper"

module Appkit
  class UserThemingTest < ActiveSupport::TestCase
    test "defaults to system color scheme and solunized light/dark themes" do
      user = users(:alice)

      assert_equal "system", user.color_scheme
      assert_equal "solunized-light", user.light_theme
      assert_equal "solunized-dark", user.dark_theme
    end
  end
end
