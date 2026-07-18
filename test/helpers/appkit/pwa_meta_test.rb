require "test_helper"

module Appkit
  class PwaMetaTest < ActionView::TestCase
    test "renders the manifest link, theme-color metas, touch icon, and VAPID meta" do
      fake_credentials = Object.new
      fake_credentials.define_singleton_method(:dig) { |*| "vapid-public-key" }
      Rails.application.define_singleton_method(:credentials) { fake_credentials }

      render partial: "appkit/shared/pwa_meta"

      assert_select "link[rel='manifest'][href=?]", manifest_path
      assert_select "meta[name='theme-color'][content='#f5f9fa'][media='(prefers-color-scheme: light)']"
      assert_select "meta[name='theme-color'][content='#012b38'][media='(prefers-color-scheme: dark)']"
      assert_select "link[rel='apple-touch-icon'][href='/icon-192.png']"
      assert_select "meta[name='apple-mobile-web-app-capable'][content='yes']"
      assert_select "meta[name='appkit-vapid-public-key'][content='vapid-public-key']"
    ensure
      Rails.application.singleton_class.remove_method(:credentials)
    end
  end
end
