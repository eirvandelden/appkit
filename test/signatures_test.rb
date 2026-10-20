require "test_helper"
require "prism"

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

  private
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
      return "no diagnostic name" unless text.match?(/steep:ignore:start\s*\z|steep:ignore( [A-Z]\w+)+\s*\z/)

      "no reason comment above" unless reason_above?(lines, line)
    end

    def reason_above?(lines, line)
      above = lines[line - 2].to_s
      return reason_above?(lines, line - 1) if above.match?(IGNORE_LINE) && !above.match?(/\A\s*#/)

      above.match?(/\A\s*#/) && !above.match?(SIGNATURE_LINE) && !above.match?(/\A\s*# steep:/)
    end
end
