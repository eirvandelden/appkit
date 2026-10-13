require "test_helper"

class AppNameTest < ActionDispatch::IntegrationTest
  setup { @original_app_name = Appkit.config.app_name }

  teardown do
    Appkit.config.app_name = @original_app_name
    I18n.backend.reload!
  end

  test "a string app_name shows on the sign-in page, first-run page, nav, page title and manifest" do
    Appkit.config.app_name = "My App"

    assert_name_on_every_page "My App"
  end

  test "a callable app_name shows on every page that names the app" do
    Appkit.config.app_name = -> { "My App" }

    assert_name_on_every_page "My App"
  end

  test "an unset app_name shows the host module name on every page" do
    Appkit.config.app_name = nil

    assert_name_on_every_page "Dummy"
  end

  test "an empty app_name shows the host module name on every page" do
    Appkit.config.app_name = ""

    assert_name_on_every_page "Dummy"
  end

  test "a callable returning nil shows the host module name on every page" do
    Appkit.config.app_name = -> { nil }

    assert_name_on_every_page "Dummy"
  end

  test "a Dutch visitor sees the nl app_name translation and an English visitor the configured name" do
    Appkit.config.app_name = "Recipe Book"
    I18n.backend.store_translations(:nl, app_name: "Receptenboek")

    names = { "nl" => "Receptenboek", "en" => "Recipe Book" }

    names.each { |locale, name| assert_name_on_signed_out_pages name, locale: locale }
    names.each { |locale, name| assert_name_in_nav name, locale: locale }
    assert_name_on_first_run_page "Receptenboek", locale: "nl"
    assert_name_on_first_run_page "Recipe Book", locale: "en"
  end

  private
    def assert_name_on_every_page(name, locale: "en")
      assert_name_on_signed_out_pages name, locale: locale
      assert_name_in_nav name, locale: locale
      assert_name_on_first_run_page name, locale: locale
    end

    def assert_name_on_signed_out_pages(name, locale:)
      get new_session_url(locale: locale)

      assert_select "title", text: name
      assert_select "h1", text: name

      get manifest_url(locale: locale)

      assert_equal name, JSON.parse(response.body)["name"]
    end

    def assert_name_in_nav(name, locale:)
      sign_in_as users(:alice)
      get root_url(locale: locale)

      assert_select "h2", text: name
      assert_select "title", text: name
    end

    def assert_name_on_first_run_page(name, locale:)
      Session.delete_all
      User.delete_all
      get first_run_url(locale: locale)

      assert_select "h1", text: name
    end
end
