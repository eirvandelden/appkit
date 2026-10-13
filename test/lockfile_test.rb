require "test_helper"

class LockfileTest < ActiveSupport::TestCase
  test "Gemfile.lock is not tracked by git" do
    assert_empty `git -C #{Appkit::Engine.root} ls-files Gemfile.lock`.strip
  end

  test "git ignores Gemfile.lock" do
    assert_equal "Gemfile.lock", `git -C #{Appkit::Engine.root} check-ignore Gemfile.lock`.strip
  end
end
