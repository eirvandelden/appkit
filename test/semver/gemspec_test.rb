require_relative "semver_test_helper"

class GemspecTest < ActiveSupport::TestCase
  def test_gem_files_exclude_script
    spec = Gem::Specification.load(File.expand_path("../../appkit.gemspec", __dir__))

    assert_empty spec.files.grep(%r{\Ascript/|\Achangelog\.d/})
  end
end
