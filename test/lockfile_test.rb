require "test_helper"

class LockfileTest < ActiveSupport::TestCase
  test "Gemfile.lock is not tracked by git" do
    assert_empty git("ls-files", "Gemfile.lock")
  end

  test "git ignores Gemfile.lock" do
    assert_equal "Gemfile.lock", git("check-ignore", "Gemfile.lock")
  end

  private
    def git(*arguments)
      IO.popen([ "git", "-C", Appkit::Engine.root.to_s, *arguments ], &:read).strip
    end
end
