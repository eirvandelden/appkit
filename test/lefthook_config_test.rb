require "test_helper"

class LefthookConfigTest < ActiveSupport::TestCase
  test "no lefthook command calls yarn" do
    assert_empty commands.select { |_, command| command["run"].to_s.match?(/\byarn\b/) }.keys
  end

  test "linters run through npx --no" do
    %w[ stylelint eslint ].each do |linter|
      runs_of(linter).each { |run| assert_match(/\Anpx --no #{linter} /, run) }
    end
  end

  test "client dependencies install with npm when the lockfile or package.json changes" do
    command = commands.fetch("client-dependencies")

    assert_equal "{package-lock.json,package.json}", command["glob"]
    assert_equal "npm install", command["run"]
  end

  test "pre-commit checks the staged sig/" do
    command = local_config.dig("pre-commit", "commands", "rbs")

    assert_equal "bundle exec rake rbs:check_staged", command["run"]
    assert_nil command["glob"]
  end

  test "pre-push runs steep" do
    command = local_config.dig("pre-push", "commands", "steep")

    assert_equal "bundle exec rake steep", command["run"]
    assert_nil command["glob"]
  end

  private
    def commands
      config.values.grep(Hash).flat_map { |hook| hook.fetch("commands", {}).to_a }.to_h
    end

    def runs_of(linter)
      config.values.grep(Hash).filter_map { |hook| hook.dig("commands", linter, "run") }
    end

    def local_config
      @local_config ||= YAML.safe_load_file(Appkit::Engine.root.join("lefthook-local.yml"))
    end

    def config
      @config ||= YAML.safe_load_file(Appkit::Engine.root.join("lefthook.yml"))
    end
end
