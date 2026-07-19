require "test_helper"

module Appkit
  class PreferencesControllerTest < ActionDispatch::IntegrationTest
    test "edit renders for the signed-in user" do
      sign_in_as users(:alice)

      get edit_preferences_url

      assert_response :success
    end

    test "update persists locale, color_scheme, light_theme, and dark_theme, then redirects with a notice" do
      sign_in_as users(:alice)

      patch preferences_url, params: {
        user: { locale: "nl", color_scheme: "dark", light_theme: "solunized-white", dark_theme: "solunized-black" }
      }

      assert_redirected_to edit_preferences_url
      follow_redirect!
      assert_equal I18n.t("appkit.preferences.update.success"), flash[:notice]

      users(:alice).reload.tap do |user|
        assert_equal "nl", user.locale
        assert_equal "dark", user.color_scheme
        assert_equal "solunized-white", user.light_theme
        assert_equal "solunized-black", user.dark_theme
      end
    end

    test "update with invalid params re-renders edit with unprocessable_entity" do
      sign_in_as users(:alice)

      patch preferences_url, params: { user: { locale: "xx" } }

      assert_response :unprocessable_entity
    end

    test "locale field and param are present by default (locale_attribute defaults to :locale)" do
      sign_in_as users(:alice)

      get edit_preferences_url
      assert_select "select#user_locale"

      patch preferences_url, params: {
        user: { locale: "nl", color_scheme: "dark", light_theme: "solunized-white", dark_theme: "solunized-black" }
      }
      assert_redirected_to edit_preferences_url

      assert_equal "nl", users(:alice).reload.locale
    end

    test "locale field and param are absent when locale_attribute is configured but the user does not respond to it" do
      with_locale_attribute(:language) do
        sign_in_as users(:alice)

        get edit_preferences_url
        assert_select "select#user_locale", count: 0
        assert_select "select#user_language", count: 0
      end
    end

    test "timezone field and param are absent when timezone_attribute is not configured" do
      sign_in_as users(:alice)

      get edit_preferences_url

      assert_select "select#user_timezone", count: 0
    end

    test "timezone field and param are present when timezone_attribute is configured and the user responds to it" do
      with_timezone_attribute(:timezone) do
        User.class_eval { attr_accessor :timezone } unless User.method_defined?(:timezone)

        sign_in_as users(:alice)

        get edit_preferences_url
        assert_select "select#user_timezone"

        patch preferences_url, params: { user: { timezone: "Amsterdam" } }
        assert_redirected_to edit_preferences_url
      end
    end

    test "field, permitted param, and persistence follow a custom timezone_attribute, not the literal :timezone" do
      with_timezone_attribute(:tz) do
        sign_in_as users(:alice)

        get edit_preferences_url
        assert_select "select#user_tz"
        assert_select "select#user_timezone", count: 0

        patch preferences_url, params: { user: { tz: "Amsterdam" } }
        assert_redirected_to edit_preferences_url

        assert_equal "Amsterdam", users(:alice).reload.tz
      end
    end

    private
      def with_timezone_attribute(attribute)
        original = Appkit.config.timezone_attribute
        Appkit.config.timezone_attribute = attribute
        yield
      ensure
        Appkit.config.timezone_attribute = original
      end

      def with_locale_attribute(attribute)
        original = Appkit.config.locale_attribute
        Appkit.config.locale_attribute = attribute
        yield
      ensure
        Appkit.config.locale_attribute = original
      end
  end
end
