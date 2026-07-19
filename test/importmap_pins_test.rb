require "test_helper"

class ImportmapPinsTest < ActiveSupport::TestCase
  test "every appkit JS controller/module lives under app/javascript/appkit/ and has a pin" do
    js_root = Appkit::Engine.root.join("app/javascript")
    stray = Dir.glob(js_root.join("**/*.js")).reject { |path| path.start_with?(js_root.join("appkit").to_s) }

    assert_empty stray, "JS files must live under app/javascript/appkit/, not the bare controllers/ namespace " \
      "(which can collide with a host app's own controllers): #{stray.join(', ')}"
  end

  test "every file under app/javascript/appkit/ has a matching importmap pin" do
    js_root = Appkit::Engine.root.join("app/javascript/appkit")
    files = Dir.glob(js_root.join("**/*.js")).map { |path| "appkit/#{Pathname.new(path).relative_path_from(js_root)}".delete_suffix(".js") }
    importmap_source = Appkit::Engine.root.join("config/importmap.rb").read
    pinned = importmap_source.scan(/pin\s+"([^"]+)"/).flatten

    assert_empty files - pinned, "these appkit JS files have no importmap pin: #{(files - pinned).join(', ')}"
  end
end
