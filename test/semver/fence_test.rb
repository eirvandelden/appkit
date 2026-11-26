require_relative "semver_test_helper"

class FenceTest < ActiveSupport::TestCase
  def test_a_plain_line_is_not_code
    assert_not Semver::Fence.new.code?("Just text.")
  end

  def test_lines_between_fences_and_the_fences_are_code
    fence = Semver::Fence.new

    assert_equal [ true, true, true, false ], [ "```ruby", "### Added", "```", "after" ].map { |line|
 fence.code?(line) }
  end

  def test_a_backtick_fence_inside_a_tilde_fence_does_not_close_it
    fence = Semver::Fence.new
    [ "~~~markdown", "```ruby" ].each { |line| fence.code?(line) }

    assert fence.code?("### Example")
    assert fence.code?("```")
    assert_predicate fence, :open?
    assert fence.code?("~~~")
    assert_not_predicate fence, :open?
  end

  def test_a_shorter_fence_does_not_close_a_longer_one
    fence = Semver::Fence.new
    [ "````", "```" ].each { |line| fence.code?(line) }

    assert_predicate fence, :open?
    fence.code?("`````")

    assert_not_predicate fence, :open?
  end

  def test_a_closing_fence_carries_no_text
    fence = Semver::Fence.new
    [ "```", "``` ruby" ].each { |line| fence.code?(line) }

    assert_predicate fence, :open?
  end

  def test_an_indented_fence_counts
    fence = Semver::Fence.new
    fence.code?("   ```ruby")

    assert_predicate fence, :open?
  end

  def test_a_backtick_opener_with_backticks_in_its_info_is_text
    assert_not Semver::Fence.new.code?("```not `a` fence")
  end
end
