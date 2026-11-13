require "test_helper"

class SignOutEntryTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:alice)
  end

  test "the sign-out tile is last and signs out" do
    get hub_url("profile")

    link = css_select("ul.tiles > li:last-child > a").first

    assert_equal "Logout", link.text.strip
    assert_signs_out(link)
  end

  test "the sign-out hub-column item is last and signs out" do
    get hub_url("profile")

    link = css_select("nav.hub-column > ul > li:last-child > a").first

    assert_equal "Logout", link.text.strip
    assert_select "nav.hub-column > ul > li:last-child data", count: 0
    assert_signs_out(link)
  end

  test "the nav page loads Turbo" do
    get hub_url("profile")

    importmap = css_select("script[type='importmap']").first.text

    assert_includes JSON.parse(importmap)["imports"].keys, "@hotwired/turbo-rails"
    assert_select "script[type='module']", text: /import "application"/
  end

  test "the sign-out link sends the page's CSRF token, as Turbo does" do
    with_forgery_protection do
      get hub_url("profile")
      token = css_select("meta[name='csrf-token']").first&.[]("content")

      assert_predicate token, :present?
      delete session_path, headers: { "X-CSRF-Token" => token }

      assert_redirected_to root_url
    end
  end

  private
    def with_forgery_protection
      before = ActionController::Base.allow_forgery_protection
      ActionController::Base.allow_forgery_protection = true
      yield
    ensure
      ActionController::Base.allow_forgery_protection = before
    end

    def assert_signs_out(link)
      assert_equal "delete", link["data-turbo-method"]
      assert_equal session_path, link["href"]

      delete link["href"]
      follow_redirect!
      follow_redirect!

      assert_equal new_session_path, request.path
      get hub_url("profile")

      assert_redirected_to new_session_url
    end
end
