require "test_helper"
require "open3"

class MvpaCssBootTest < ActiveSupport::TestCase
  ROOT = Appkit::Engine.root
  GEMFILE_LINE = %(gem "mvpa-css", github: "eirvandelden/mvpa.css")
  BOOT_WITHOUT_MVPA_CSS = <<~RUBY
    require "bundler/setup"
    spec = Gem.loaded_specs.fetch("mvpa-css")
    $LOAD_PATH.reject! { |path| path.start_with?(spec.full_gem_path) }
    require "./test/dummy/config/environment"
  RUBY

  test "booting without mvpa-css in the bundle raises with the Gemfile line" do
    output, status = Open3.capture2e(isolated_env, RbConfig.ruby, "-e", BOOT_WITHOUT_MVPA_CSS, chdir: ROOT.to_s)

    assert_not status.success?
    assert_includes output, "Appkit::MissingCoGem"
    assert_includes output, GEMFILE_LINE
  end

  test "booting loads the mvpa-css engine before initialize" do
    classes = Rails.application.railties.map(&:class)

    assert_includes classes, ::Mvpa::Css::Engine
    assert_operator classes.index(::Mvpa::Css::Engine), :<, classes.index(Appkit::Engine)
  end

  private
    # A git hook exports GIT_DIR, which would point git in the subprocess at the wrong repository.
    def isolated_env
      ENV.keys.grep(/\AGIT_/).index_with(nil).merge(
        "BUNDLE_GEMFILE" => ROOT.join("Gemfile").to_s, "RAILS_ENV" => "test"
      )
    end
end
