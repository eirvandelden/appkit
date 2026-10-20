require "test_helper"
require "prism"
require "open3"
require "tmpdir"
require "fileutils"

class SignaturesTest < ActiveSupport::TestCase
  ROOT = Appkit::Engine.root
  SOURCE_GLOBS = %w[app/**/*.rb lib/**/*.rb].freeze
  ATTRIBUTE_CALLS = %i[attr_reader attr_writer attr_accessor].freeze
  SIGNATURE_LINE = /\A\s*#(:| @rbs)/
  IGNORE_LINE = /steep:ignore/

  test "every method in app and lib has an inline signature" do
    misses = source_files.flat_map { |path| unsigned_members(path) }

    assert_empty misses, "Members without an inline signature and a generated member:\n#{misses.join("\n")}"
  end

  test "every steep:ignore names its diagnostic and has a reason above" do
    misses = source_files.flat_map { |path| bad_ignores(path) }

    assert_empty misses, "steep:ignore comments without a diagnostic name or a reason:\n#{misses.join("\n")}"
  end

  test "rbs:generate rewrites the sig file of a changed signature" do
    in_signature_copy do |dir|
      write_fixture_link(dir, "String")
      rake(dir, "rbs:generate")

      assert_includes dir.join("sig/models/appkit/qr_code_link.rbs").read, "def signed: () -> String"

      write_fixture_link(dir, "Integer")
      rake(dir, "rbs:generate")

      assert_includes dir.join("sig/models/appkit/qr_code_link.rbs").read, "def signed: () -> Integer"
    end
  end

  test "rbs:generate leaves sig/manifest.yaml unchanged" do
    in_signature_copy do |dir|
      dir.join("sig/manifest.yaml").write("dependencies:\n  - name: set\n")

      rake(dir, "rbs:generate")

      assert_equal "dependencies:\n  - name: set\n", dir.join("sig/manifest.yaml").read
    end
  end

  test "rbs:check fails when sig/ is stale" do
    in_signature_copy do |dir|
      write_fixture_link(dir, "String")
      commit_generated_sig(dir)

      write_fixture_link(dir, "Integer")
      output, status = rake(dir, "rbs:check")

      assert_not status.success?
      assert_includes output, "sig/models/appkit/qr_code_link.rbs"
    end
  end

  test "rbs:check fails when a committed signature has no source" do
    in_signature_copy do |dir|
      write_fixture_link(dir, "String")
      commit_generated_sig(dir)

      dir.join("app/models/appkit/qr_code_link.rb").delete
      output, status = rake(dir, "rbs:check")

      assert_not status.success?
      assert_includes output, "sig/models/appkit/qr_code_link.rbs"
    end
  end

  test "rbs:check fails when a new source has no committed signature" do
    in_signature_copy do |dir|
      write_fixture_link(dir, "String")
      commit_generated_sig(dir)

      dir.join("app/models/appkit/extra.rb").write(<<~RUBY)
        module Appkit
          #: () -> String
          def self.extra = "extra"
        end
      RUBY
      output, status = rake(dir, "rbs:check")

      assert_not status.success?
      assert_includes output, "sig/models/appkit/extra.rbs"
    end
  end

  test "rbs:check leaves the index unchanged" do
    in_signature_copy do |dir|
      write_fixture_link(dir, "String")
      commit_generated_sig(dir)

      dir.join("app/models/appkit/qr_code_link.rb").delete
      rake(dir, "rbs:check")

      assert_equal "", git(dir, "diff", "--cached", "--name-only")
    end
  end

  test "rbs:check_staged ignores an unstaged signature change" do
    in_signature_copy do |dir|
      write_fixture_link(dir, "String")
      commit_generated_sig(dir)

      write_fixture_link(dir, "Integer")
      output, status = rake(dir, "rbs:check_staged")

      assert_predicate status, :success?, output
    end
  end

  test "rbs:check_staged fails on a staged signature change without its sig, and regenerates sig/" do
    in_signature_copy do |dir|
      write_fixture_link(dir, "String")
      commit_generated_sig(dir)

      write_fixture_link(dir, "Integer")
      git(dir, "add", "app/models/appkit/qr_code_link.rb")
      output, status = rake(dir, "rbs:check_staged")

      assert_not status.success?
      assert_includes output, "sig/models/appkit/qr_code_link.rbs"
      assert_includes dir.join("sig/models/appkit/qr_code_link.rbs").read, "def signed: () -> Integer"
    end
  end

  test "rbs:check_staged passes when the staged sig matches the staged signatures" do
    in_signature_copy do |dir|
      write_fixture_link(dir, "String")
      commit_generated_sig(dir)

      write_fixture_link(dir, "Integer")
      rake(dir, "rbs:generate")
      git(dir, "add", ".")
      output, status = rake(dir, "rbs:check_staged")

      assert_predicate status, :success?, output
    end
  end

  test "rbs:check passes when sig/ matches" do
    in_signature_copy do |dir|
      write_fixture_link(dir, "String")
      commit_generated_sig(dir)

      output, status = rake(dir, "rbs:check")

      assert_predicate status, :success?, output
    end
  end

  test "sig/ is not ignored when the global ignore file ignores sig/" do
    Tempfile.create("global-ignore") do |file|
      file.write("sig/\n")
      file.flush
      %w[sig/manifest.yaml sig/models/appkit/qr_code_link.rbs].each do |path|
        _output, status = Open3.capture2e("git", "-c", "core.excludesFile=#{file.path}", "check-ignore", "--no-index",
"-q", path, chdir: ROOT.to_s)

        assert_equal 1, status.exitstatus, "#{path} is ignored"
      end
    end
  end

  test "the gemspec packages sig/" do
    files = Gem::Specification.load(ROOT.join("appkit.gemspec").to_s).files

    assert_includes files, "sig/manifest.yaml"
    assert files.any? { |file| file.start_with?("sig/") && file.end_with?(".rbs") }
  end

  private
    def rake(dir, task)
      Open3.capture2e(isolated_env, "bundle", "exec", "rake", task, chdir: dir.to_s)
    end

    # A git hook exports GIT_DIR, which would point git in the temp copy at the real repository.
    def isolated_env
      ENV.keys.grep(/\AGIT_/).index_with(nil).merge("BUNDLE_GEMFILE" => ROOT.join("Gemfile").to_s)
    end

    def in_signature_copy
      Dir.mktmpdir("appkit-signatures") do |tmp|
        dir = Pathname(tmp)
        %w[app lib sig rakelib].each { |name| FileUtils.cp_r(ROOT.join(name), dir) if ROOT.join(name).exist? }
        FileUtils.cp(ROOT.join(".gitignore"), dir.join(".gitignore"))
        dir.join("sig").mkpath
        dir.join("Rakefile").write("")
        yield dir
      end
    end

    def write_fixture_link(dir, return_type)
      dir.join("app/models/appkit").mkpath
      dir.join("app/models/appkit/qr_code_link.rb").write(<<~RUBY)
        module Appkit
          class QrCodeLink
            #: () -> #{return_type}
            def signed
              "signed"
            end
          end
        end
      RUBY
    end

    def commit_generated_sig(dir)
      output, status = rake(dir, "rbs:generate")

      assert_predicate status, :success?, output

      git(dir, "init", "-q")
      git(dir, "add", ".")
      git(dir, "-c", "user.name=Test", "-c", "user.email=test@example.com", "-c", "commit.gpgsign=false",
        "commit", "-q", "-m", "baseline")
    end

    def git(dir, *arguments)
      output, status = Open3.capture2e(isolated_env, "git", "-c", "core.hooksPath=/dev/null", *arguments,
        chdir: dir.to_s)

      assert_predicate status, :success?, "git #{arguments.join(" ")} failed:\n#{output}"
      output
    end

    def source_files
      SOURCE_GLOBS.flat_map { |glob| Dir[ROOT.join(glob)] }.sort
    end

    def relative(path)
      Pathname(path).relative_path_from(ROOT).to_s
    end

    def generated_signature(path)
      relative_path = relative(path).sub(%r{\A(app|lib)/}, "").sub(/\.rb\z/, ".rbs")
      file = ROOT.join("sig", relative_path)
      file.exist? ? file.read : ""
    end

    def unsigned_members(path)
      lines = File.readlines(path)
      generated = generated_signature(path)

      members(Prism.parse_file(path).value).filter_map do |node|
        problem = member_problem(node, lines, generated)
        "#{relative(path)}:#{node.location.start_line} #{node.name} (#{problem})" if problem
      end
    end

    def members(node)
      own = node.is_a?(Prism::DefNode) || attribute_call?(node) ? [ node ] : []
      own + node.compact_child_nodes.flat_map { |child| members(child) }
    end

    def attribute_call?(node)
      node.is_a?(Prism::CallNode) && node.receiver.nil? && ATTRIBUTE_CALLS.include?(node.name)
    end

    def member_problem(node, lines, generated)
      if node.is_a?(Prism::DefNode)
        def_problem(node, lines, generated)
      else
        attribute_problem(node, lines, generated)
      end
    end

    def def_problem(node, lines, generated)
      return "no #: or # @rbs comment above" unless signature_above?(lines, node.location.start_line)

      "not in the generated sig" unless generated.match?(/^\s*def (self\.)?#{Regexp.escape(node.name.to_s)}:/)
    end

    def signature_above?(lines, line)
      comment_block_above(lines, line).any? { |text| text.match?(SIGNATURE_LINE) }
    end

    def comment_block_above(lines, line)
      block = []
      index = line - 2
      while index >= 0 && lines[index].match?(/\A\s*#/)
        block << lines[index]
        index -= 1
      end
      block
    end

    def attribute_problem(node, lines, generated)
      return "no trailing #: type" unless lines[node.location.end_line - 1].match?(/#:\s*\S/)

      names = node.arguments.arguments.map { |argument| argument.unescaped }
      missing = names.reject { |name| generated.match?(/^\s*attr_\w+ #{Regexp.escape(name)}:/) }
      "not in the generated sig: #{missing.join(", ")}" if missing.any?
    end

    def bad_ignores(path)
      lines = File.readlines(path)

      Prism.parse_file(path).comments.filter_map do |comment|
        text = comment.slice
        next unless text.match?(IGNORE_LINE) && !text.match?(/steep:ignore:end/)

        problem = ignore_problem(text, lines, comment.location.start_line)
        "#{relative(path)}:#{comment.location.start_line} (#{problem})" if problem
      end
    end

    def ignore_problem(text, lines, line)
      return "no diagnostic name" unless text.match?(/steep:ignore:start\s*\z|steep:ignore [A-Z]\w*(, [A-Z]\w*)*\s*\z/)

      "no reason comment above" unless reason_above?(lines, line)
    end

    def reason_above?(lines, line)
      return true if comment_block_above(lines, line).any? { |text| plain_comment?(text) }

      above = lines[line - 2].to_s
      above.match?(IGNORE_LINE) && !above.match?(/\A\s*#/) && reason_above?(lines, line - 1)
    end

    def plain_comment?(text)
      text.match?(/\A\s*# \S/) && !text.match?(/\A\s*# (@rbs|steep:)/)
    end
end
