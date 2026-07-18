require "test_helper"

module Appkit
  class PwaControllerTest < ActionDispatch::IntegrationTest
    test "manifest renders valid JSON built from configuration" do
      get manifest_url

      assert_response :success
      assert_equal "no-cache", response.headers["Cache-Control"]

      manifest = JSON.parse(response.body)

      assert_equal "Dummy", manifest["name"]
      assert_equal "standalone", manifest["display"]
      assert_equal "/", manifest["start_url"]
      assert_equal "/", manifest["scope"]
      assert_equal "#1a73e8", manifest["theme_color"]
      assert_equal "#f5f9fa", manifest["background_color"]
    end

    test "manifest emits an icon entry per configured icon path with inferred sizes" do
      get manifest_url

      icons = JSON.parse(response.body)["icons"]

      assert_equal Appkit.config.icons.size, icons.size

      svg_icon = icons.find { |icon| icon["src"] == "/icon.svg" }
      assert_nil svg_icon["sizes"]

      icon_192 = icons.find { |icon| icon["src"] == "/icon-192.png" }
      assert_equal "192x192", icon_192["sizes"]

      icon_512 = icons.find { |icon| icon["src"] == "/icon-512.png" }
      assert_equal "512x512", icon_512["sizes"]
      assert_nil icon_512["purpose"]

      mask_icon = icons.find { |icon| icon["src"] == "/icon-mask-512.png" }
      assert_equal "512x512", mask_icon["sizes"]
      assert_equal "maskable", mask_icon["purpose"]
    end

    test "service worker does not precache literal digested asset paths (Clocky regression)" do
      get service_worker_url

      assert_response :success
      assert_equal "no-cache", response.headers["Cache-Control"]
      assert_no_match %r{/assets/[\w-]+\.(css|js)}, response.body
    end

    test "service worker registers install, activate, push, and notificationclick handlers" do
      get service_worker_url

      assert_match(/addEventListener\(['"]install['"]/, response.body)
      assert_match(/addEventListener\(['"]activate['"]/, response.body)
      assert_match(/addEventListener\(['"]push['"]/, response.body)
      assert_match(/addEventListener\(['"]notificationclick['"]/, response.body)
    end

    test "service worker cache name includes the engine version" do
      get service_worker_url

      assert_match Appkit::VERSION, response.body
    end
  end
end
