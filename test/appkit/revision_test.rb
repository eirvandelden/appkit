require "test_helper"

class Appkit::RevisionTest < ActiveSupport::TestCase
  Spec = Struct.new(:source)
  GitSource = Struct.new(:revision)

  test "returns the Bundler git revision when the spec has one" do
    spec = Spec.new(GitSource.new("a" * 40))

    assert_equal "a" * 40, Appkit::Revision.new(spec: spec).to_s
  end

  test "two Bundler revisions give two different values" do
    first = Appkit::Revision.new(spec: Spec.new(GitSource.new("a" * 40)))
    second = Appkit::Revision.new(spec: Spec.new(GitSource.new("b" * 40)))

    assert_not_equal first.to_s, second.to_s
  end

  test "falls back to Appkit::VERSION when the source has no revision" do
    assert_equal Appkit::VERSION, Appkit::Revision.new(spec: Spec.new(Object.new)).to_s
  end

  test "falls back to Appkit::VERSION when there is no spec" do
    assert_equal Appkit::VERSION, Appkit::Revision.new(spec: nil).to_s
  end
end
