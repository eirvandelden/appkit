require "test_helper"

module Appkit
  class AppNameTest < ActiveSupport::TestCase
    teardown { I18n.backend.reload! }

    test "returns a configured string" do
      assert_equal "My App", app_name("My App").to_s
    end

    test "calls a configured callable" do
      assert_equal "My App", app_name(-> { "My App" }).to_s
    end

    test "prefers the app_name translation for the current locale" do
      I18n.backend.store_translations(:nl, app_name: "Receptenboek")

      I18n.with_locale(:nl) { assert_equal "Receptenboek", app_name("Recipe Book").to_s }
    end

    test "ignores the translation in a locale that does not define it" do
      I18n.backend.store_translations(:nl, app_name: "Receptenboek")

      I18n.with_locale(:en) { assert_equal "Recipe Book", app_name("Recipe Book").to_s }
    end

    test "ignores an app_name translation reached only through I18n fallbacks" do
      original_backend = I18n.backend
      original_fallbacks = I18n.fallbacks
      I18n.backend = fallback_backend
      I18n.fallbacks = { en: [ :en, :nl ] }
      I18n.backend.store_translations(:nl, app_name: "Receptenboek")

      I18n.with_locale(:en) { assert_equal "Recipe Book", app_name("Recipe Book").to_s }
    ensure
      I18n.backend = original_backend
      I18n.fallbacks = original_fallbacks
    end

    test "ignores a non-string app_name translation" do
      I18n.backend.store_translations(:en, app_name: { title: "Nested" })

      assert_equal "Recipe Book", app_name("Recipe Book").to_s
    end

    test "treats an empty string as unset" do
      assert_equal "My Recipe Book", app_name("").to_s
    end

    test "treats a callable returning nil as unset" do
      assert_equal "My Recipe Book", app_name(-> { nil }).to_s
    end

    test "treats a callable returning an empty string as unset" do
      assert_equal "My Recipe Book", app_name(-> { "" }).to_s
    end

    test "treats a callable returning false as unset" do
      assert_equal "My Recipe Book", app_name(-> { false }).to_s
    end

    test "returns a string when a callable gives a symbol" do
      assert_equal "Recipes", app_name(-> { :Recipes }).to_s
    end

    test "falls back to the host module name split into words when nothing is configured" do
      assert_equal "My Recipe Book", app_name(nil).to_s
    end

    test "shows a blank name instead of raising when the host application has no module" do
      assert_equal "", AppName.new(nil, host_module_name: nil).to_s
    end

    private
      def app_name(configured)
        AppName.new(configured, host_module_name: "MyRecipeBook")
      end

      def fallback_backend
        Class.new(I18n::Backend::Simple) { include I18n::Backend::Fallbacks }.new
      end
  end
end
