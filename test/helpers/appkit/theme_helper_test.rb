require "test_helper"

module Appkit
  class ThemeHelperTest < ActionView::TestCase
    teardown { Current.user = nil }

    test "returns an empty hash when there is no current user" do
      Current.user = nil

      assert_equal({}, theme_attributes)
    end

    test "system color scheme omits data-theme but always includes data-color-scheme" do
      Current.user = users(:alice).tap { |u| u.update!(color_scheme: :system) }

      assert_equal({
        "data-color-scheme": "system",
        "data-light-theme": "solunized-light",
        "data-dark-theme": "solunized-dark"
      }, theme_attributes)
    end

    test "light color scheme sets data-theme to the light theme value" do
      Current.user = users(:alice).tap { |u| u.update!(color_scheme: :light, light_theme: "solunized-white") }

      assert_equal "solunized-white", theme_attributes[:"data-theme"]
    end

    test "dark color scheme sets data-theme to the dark theme value" do
      Current.user = users(:alice).tap { |u| u.update!(color_scheme: :dark, dark_theme: "solunized-black") }

      assert_equal "solunized-black", theme_attributes[:"data-theme"]
    end

    test "saved_theme_attributes excludes data-theme" do
      Current.user = users(:alice).tap { |u| u.update!(color_scheme: :dark) }

      assert_not saved_theme_attributes.key?(:"data-theme")
    end
  end
end
