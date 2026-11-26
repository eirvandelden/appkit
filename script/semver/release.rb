module Semver
  # The next release, cut from the pending fragments.
  class Release
    class NoBaseline < StandardError; end

    ATTEMPTS = 3 #: Integer

    #: (repository: Repository, ?dir: String, ?today: Date) -> Release
    def self.pending(repository:, dir: "changelog.d", today: Date.today)
      new(repository: repository, dir: dir, today: today)
    end

    #: (repository: Repository, dir: String, today: Date) -> void
    def initialize(repository:, dir:, today:)
      @repository = repository
      @dir = dir
      @today = today
      @last = repository.merged_versions.max or raise NoBaseline, "no X.Y.Z tag on this branch: run the retro first"
      @fragments = ordered(Fragment.pending(dir))
    end

    #: () -> Version
    def version
      @last.bump(level)
    end

    #: () -> bool
    def due?
      !@repository.head_is?(@last)
    end

    #: () -> String
    def notes
      "## #{version} - #{@today.strftime('%F')}\n\n#{body}\n"
    end

    #: () -> void
    def cut
      @repository.refresh
      @repository.reconcile(@repository.merged_versions)
      ATTEMPTS.times do
        return if attempt
      end
      raise Repository::CommandFailed, "release not published after #{ATTEMPTS} attempts: #{@rejection}"
    end

    protected

    # Rendered once, before the release commit exists, so the changelog and the GitHub Release agree.
    #: () -> String
    def body
      @body ||= render_body
    end

    # Only #cut calls this, on a Release it has just replanned from the tip of main.
    #: () -> void
    def publish
      paths = Stamp.apply(version: version, notes: notes, fragments: @fragments)
      @repository.stage(version, paths: paths)
      @repository.publish
      @repository.ensure_release(version, body)
    end

    private

    def ordered(fragments)
      order = @repository.in_merge_order(fragments.map(&:path))
      fragments.sort_by { |fragment| order.index(fragment.path) }
    end

    def level
      @fragments.map(&:level).max || Level::PATCH
    end

    def render_body
      sections = Fragment::SECTIONS.filter_map { |name| section(name) }
      sections = [ "### Changed\n#{subject_lines}" ] if sections.empty?
      sections.join("\n\n")
    end

    def section(name)
      lines = name == "Upgrading" ? upgrading_lines : @fragments.flat_map { |fragment|
 fragment.sections.fetch(name, []) }
      return if lines.empty?

      "### #{name}\n#{lines.join("\n")}"
    end

    # One continuous list across fragments, in the order they were added. A step reference in a
    # fragment follows its step to the new number.
    def upgrading_lines
      offset = 0
      @fragments.flat_map do |fragment|
        steps = steps_of(fragment.sections.fetch("Upgrading", []))
        numbers = steps.each_with_index.to_h { |step, index| [ step.first[/\A\d+/], (offset + index + 1).to_s ] }
        offset += steps.size
        renumber(steps, numbers, offset - steps.size)
      end
    end

    def steps_of(lines)
      fenced = false
      lines.slice_before do |line|
        fenced = !fenced if line.lstrip.start_with?("```")
        !fenced && line.match?(/\A\d+\.\s/)
      end.to_a
    end

    def renumber(steps, numbers, offset)
      steps.each_with_index.flat_map do |step, index|
        text = step.map { |line| line.gsub(/\b(steps? )(\d+)\b/i) { "#{$1}#{numbers.fetch($2, $2)}" } }
        [ "#{offset + index + 1}. #{text.first.sub(/\A\d+\.\s*/, '')}", *text.drop(1) ]
      end
    end

    def subject_lines
      @repository.subjects_since(@last).map { |subject| "- #{subject}" }.join("\n")
    end

    # Replans from the tip of main. Returns true when nothing is left to do.
    def attempt
      @repository.refresh
      release = self.class.pending(repository: @repository, dir: @dir, today: @today)
      return true unless release.due?

      release.publish
      true
    rescue Repository::Rejected => error
      @rejection = error.message
      false
    end
  end
end
