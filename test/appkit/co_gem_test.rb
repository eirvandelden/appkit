require "test_helper"
require "tmpdir"

module Appkit
  class CoGemTest < ActiveSupport::TestCase
    test "ensure_loaded raises MissingCoGem with the Gemfile line when the gem is not in the bundle" do
      co_gem = CoGem.new(name: "appkit-absent-co-gem", github: "example/absent")

      error = assert_raises(MissingCoGem) { co_gem.ensure_loaded }

      assert_includes error.message, %(gem "appkit-absent-co-gem", github: "example/absent")
    end

    test "ensure_loaded loads an installed co-gem without raising" do
      assert_nothing_raised { CoGem.new(name: "mvpa-css", github: "eirvandelden/mvpa.css").ensure_loaded }
    end

    test "ensure_loaded re-raises a LoadError from inside the co-gem" do
      Dir.mktmpdir("appkit-broken-co-gem") do |dir|
        File.write(File.join(dir, "broken_co_gem.rb"), %(require "broken_co_gem/absent_part"\n))
        $LOAD_PATH.unshift(dir)

        error = assert_raises(LoadError) { CoGem.new(name: "broken_co_gem", github: "example/broken").ensure_loaded }

        assert_not_kind_of MissingCoGem, error
        assert_equal "broken_co_gem/absent_part", error.path
      ensure
        $LOAD_PATH.delete(dir)
      end
    end
  end
end
