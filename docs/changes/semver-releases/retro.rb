#!/usr/bin/env ruby
# One-off retro pass: gives the merged PRs their semver versions. Removed by `deliver`.
#
#   ruby docs/changes/semver-releases/retro.rb table                 writes retro-table.md
#   ruby docs/changes/semver-releases/retro.rb apply [--execute]     dry run by default
#   ruby docs/changes/semver-releases/retro.rb verify                compares tags and CHANGELOG.md with the table
#
# Run from the repository root. `apply` refuses until retro-table.md says `Status: accepted`.
require "json"
require "open3"
require_relative "../../../script/semver"

module Retro
  TABLE = File.expand_path("retro-table.md", __dir__)
  SECTIONS = Semver::Fragment::SECTIONS

  Unit = Data.define(
    :number,     #: untyped
    :title,      #: untyped
    :sha,        #: untyped
    :date,       #: untyped
    :tip_index,  #: untyped
    :floor,      #: untyped
    :reasons,    #: untyped
    :direct      #: untyped
  )

  #: (*untyped, **untyped) -> untyped
  def self.git(*args, allow_failure: false)
    out, err, status = Open3.capture3("git", *args)
    raise "git #{args.join(' ')}: #{err}" unless status.success? || allow_failure

    out
  end

  #: (*untyped, **untyped) -> untyped
  def self.gh(*args, allow_failure: false)
    out, err, status = Open3.capture3("gh", *args)
    raise "gh #{args.join(' ')}: #{err}" unless status.success? || allow_failure

    status.success? ? out : nil
  end

  #: (*untyped, **untyped) -> untyped
  def self.chain(ref)
    git("log", "--first-parent", "--reverse", "--format=%H\t%P\t%cs\t%s", ref).split("\n").map { |line|
 line.split("\t", 4) }
  end

  #: (*untyped, **untyped) -> untyped
  def self.pull_titles
    out, = Open3.capture2("gh", "pr", "list", "--state", "merged", "--limit", "200", "--json", "number,title")
    JSON.parse(out).to_h { |pr| [ pr["number"], pr["title"] ] }
  rescue StandardError
    {}
  end

  # Units in first-parent order: the merges. Returns [baseline_sha, units]; direct commits sit in `direct`.
  #: (*untyped, **untyped) -> untyped
  def self.units(ref)
    titles = pull_titles
    commits = chain(ref)
    first_merge = commits.index { |entry| entry[1].split.size == 2 }
    baseline = commits[first_merge - 1].first
    pending = []
    units = []
    commits[first_merge..].each_with_index do |(sha, parents, date, subject), offset|
      if parents.split.size == 2
        units << unit(sha, parents.split, date, subject, titles, pending, first_merge + offset)
        pending = []
      else
        pending << "#{sha[0, 7]} #{subject}"
      end
    end
    [ baseline, units, pending ]
  end

  #: (*untyped, **untyped) -> untyped
  def self.unit(sha, parents, date, subject, titles, pending, index)
    number = subject[/#(\d+)/, 1].to_i
    findings = Semver::SurfaceChange.between(base: parents[0], head: parents[1]).findings
    floor = findings.floor
    reasons = findings.filter_map { |finding| "#{finding.rule}: #{finding.reason}" if finding.level == floor }
    Unit.new(number: number, title: titles.fetch(number, subject), sha: sha, date: date, tip_index: index,
             floor: floor, reasons: reasons.first(3), direct: pending)
  end

  #: (*untyped, **untyped) -> untyped
  def self.levels(text)
    text.lines.grep(/\A\|\s*\d+\s*\|/).map { |line| line.split("|").map(&:strip)[9] }
  end

  #: (*untyped, **untyped) -> untyped
  def self.rows(text)
    text.lines.grep(/\A\|\s*\d+\s*\|/).map { |line| line.split("|").map(&:strip) }
  end

  #: (*untyped, **untyped) -> untyped
  def self.versions(levels)
    version = Semver::Version.parse("0.1.0")
    levels.each_with_index.map { |level, index| index.zero? ? version : version = version.bump(Semver::Level.parse(level)) }
  end

  # CHANGELOG.md text per unit, as it stood then: the lines each merge added to the file, with the text they
  # had in that merge. A later edit of a line belongs to the merge that made it, so an app that reads only
  # the sections up to one version still finds the steps that version needed. Slot 0 is the baseline file.
  #: (*untyped, **untyped) -> untyped
  def self.changelog_sections(_ref, baseline_sha, units)
    shas = [ baseline_sha, *units.map(&:sha) ]
    shas.each_with_index.map { |sha, index| added_changelog(index.zero? ? nil : shas[index - 1], sha) }
  end

  #: (*untyped, **untyped) -> untyped
  def self.added_changelog(base, head)
    lines = git("show", "#{head}:CHANGELOG.md", allow_failure: true).lines
    added = added_indexes(base, head, lines.size)
    section = Hash.new { |hash, key| hash[key] = [] }
    heading = nil
    lines.each_with_index do |line, index|
      heading = line[/\A### (.+)/, 1] || heading
      next if line.start_with?("#") || line.strip.empty? || heading.nil? || !added.include?(index)

      section[heading] << line.chomp
    end
    section
  end

  # Zero-based line numbers of the head file that the base lacks. Without a base, every line.
  #: (*untyped, **untyped) -> untyped
  def self.added_indexes(base, head, size)
    return (0...size).to_a unless base

    diff = git("diff", "-U0", "--no-color", base, head, "--", "CHANGELOG.md")
    diff.scan(/^@@ -\S+ \+(\d+)(?:,(\d+))? @@/).flat_map do |start, count|
      first = start.to_i - 1
      (first...(first + (count ? count.to_i : 1))).to_a
    end
  end

  # The split numbers the Upgrading steps again within each version, so "step 8" in a step's text follows
  # the step it names: the new number inside the same version, or "step 2 of 6.0.0" when it moved to another.
  #: (*untyped, **untyped) -> untyped
  def self.remap_step_references(sections, versions)
    placement = step_placement(sections)
    sections.each_with_index do |parts, slot|
      next unless parts.key?("Upgrading")

      parts["Upgrading"] = parts["Upgrading"].map do |line|
        line.gsub(/\b(steps?) (\d+(?:(?:,| and|–|-) ?\d+)*)/) do
          "#{Regexp.last_match(1)} #{Regexp.last_match(2).gsub(/\d+/) { |old|
 renumbered(old, slot, placement, versions) }}"
        end
      end
    end
  end

  # Every version slot and new position of an Upgrading step, by the number it had before the split, in
  # version order. A later version may rewrite a numbered step, so a number can sit in several slots.
  #: (*untyped, **untyped) -> untyped
  def self.step_placement(sections)
    sections.each_with_index.with_object(Hash.new { |hash, key| hash[key] = [] }) do |(parts, slot), placement|
      position = 0
      parts.fetch("Upgrading", []).each_with_index do |line, index|
        next unless line.match?(/\A\d+\.\s/) || index.zero?

        position += 1
        old = line[/\A(\d+)\./, 1]
        placement[old] << [ slot, position ] if old
      end
    end
  end

  #: (*untyped, **untyped) -> untyped
  def self.renumbered(old, slot, placement, versions)
    target, position = placement[old].find { |candidate, _| candidate == slot } || placement[old].first
    return old unless target

    target == slot ? position.to_s : "#{position} of #{versions[target]}"
  end

  #: (*untyped, **untyped) -> untyped
  def self.number(steps)
    grouped = steps.each_with_object([]) { |line, all|
 line.match?(/\A\d+\.\s/) || all.empty? ? all << line.sub(/\A\d+\.\s*/, "") : all.last << "\n#{line}" }
    grouped.each_with_index.map { |step, index| "#{index + 1}. #{step}" }
  end

  #: (*untyped, **untyped) -> untyped
  def self.section_text(version, date, parts, title)
    parts = { "Changed" => [ "- #{title}" ] } if parts.empty?
    body = SECTIONS.filter_map do |name|
      lines = parts.fetch(name, []).reject(&:empty?)
      next if lines.empty?

      "### #{name}\n#{(name == 'Upgrading' ? number(lines) : lines).join("\n")}"
    end
    "## #{version} - #{date}\n\n#{body.join("\n\n")}\n"
  end

  #: (*untyped, **untyped) -> untyped
  def self.plan(ref, text)
    baseline_sha, units, = units(ref)
    rows = rows(text)
    raise "table has #{rows.size} rows, the history has #{units.size + 1}" unless rows.size == units.size + 1

    versions = versions(rows.map { |row| row[9] })
    sections = changelog_sections(ref, baseline_sha, units)
    remap_step_references(sections, versions)
    entries = [ [ baseline_sha, git("show", "-s", "--format=%cs", baseline_sha).strip, "Baseline" ] ] +
              units.map { |unit| [ unit.sha, unit.date, unit.title ] }
    entries.each_with_index.map do |(sha, date, title), index|
      { sha: sha, version: versions[index], date: date, title: title,
notes: section_text(versions[index], date, sections[index], title) }
    end
  end

  #: (*untyped, **untyped) -> untyped
  def self.table(ref)
    baseline_sha, units, leftover = units(ref)
    head = git("rev-parse", ref).strip
    lines = [ "# Retro table", "", "Status: draft", "", "Baseline SHA: #{head}", "",
              "Edit the Level column (patch, minor or major), then set `Status: accepted`.",
              "The Version column is recomputed from the Level column.", "",
              "| # | Version | PR | Merge | Date | Title | Detected | Notes | Level |",
              "|---|---|---|---|---|---|---|---|---|" ]
    version = Semver::Version.parse("0.1.0")
    lines << "| 0 | #{version} | - | #{baseline_sha[0,
7]} | | Baseline: everything before the first merge | - | direct commits | patch |"
    sections = changelog_sections(ref, baseline_sha, units)
    units.each_with_index do |unit, index|
      upgrading = sections[index + 1].fetch("Upgrading", []).any?
      level = upgrading ? Semver::Level::MAJOR : unit.floor
      version = version.bump(level)
      notes = [ ("changelog has Upgrading" if upgrading), (unit.reasons.join(", ") unless unit.reasons.empty?),
                ("direct commits: #{unit.direct.join('; ')}" unless unit.direct.empty?) ].compact
      note = notes.join(" / ")
      lines << "| #{index + 1} | #{version} | ##{unit.number} | #{unit.sha[0,
7]} | #{unit.date} | #{unit.title} | #{unit.floor} | #{note} | #{level} |"
    end
    lines << "" << "Direct commits after the last merge, released by the next merge: #{leftover.size}" if leftover.any?
    File.write(TABLE, "#{lines.join("\n")}\n")
    puts "wrote #{TABLE} for baseline #{head}"
  end

  #: (*untyped, **untyped) -> untyped
  def self.apply(ref, execute)
    text = File.read(TABLE)
    abort "retro-table.md is not accepted" unless text.match?(/^Status: accepted/)
    baseline = text[/^Baseline SHA: (\h{40})/, 1]
    abort "baseline #{baseline} is not #{git('rev-parse',
ref).strip}: a merge happened, run `table` again and review the new rows" unless git(
"rev-parse", ref).strip == baseline
    entries = plan(ref, text)
    entries.each { |entry| puts "#{entry[:version]}  #{entry[:sha][0, 7]}  #{entry[:title]}" }
    return puts("dry run: pass --execute to tag, release and rewrite CHANGELOG.md") unless execute

    publish(entries)
    rewrite_changelog(entries)
  end

  # Resumable: a tag that exists at the right commit and a Release that exists are reused, so a retry
  # after a partial failure finishes the work instead of failing on the first tag.
  #: (*untyped, **untyped) -> untyped
  def self.publish(entries)
    git("fetch", "origin", "--tags")
    entries.each { |entry| ensure_tag(entry) }
    git("push", "origin", *entries.map { |entry| "refs/tags/#{entry[:version]}" })
    entries.each { |entry| ensure_release(entry) }
    entries.group_by { |entry| entry[:version].major }.each_value do |group|
      newest = group.last[:version]
      git("tag", "-f", newest.major_tag, newest.to_s)
      git("push", "--force", "origin", "refs/tags/#{newest.major_tag}")
    end
  end

  #: (*untyped, **untyped) -> untyped
  def self.ensure_tag(entry)
    problem = tag_problems(entry).first or return
    raise problem unless problem.include?("is missing")

    git("tag", entry[:version].to_s, entry[:sha])
  end

  #: (*untyped, **untyped) -> untyped
  def self.ensure_release(entry)
    tag = entry[:version].to_s
    return if gh("release", "view", tag, allow_failure: true)

    gh("release", "create", tag, "--title", tag, "--verify-tag", "--notes", entry[:notes].sub(/\A.*?\n\n/m, ""))
  end

  #: (*untyped, **untyped) -> untyped
  def self.rewrite_changelog(entries)
    current = File.read("CHANGELOG.md")
    header = current[0...(current.index(/^## /) || current.length)]
    File.write("CHANGELOG.md", header + entries.reverse.map { |entry| entry[:notes] }.join("\n"))
    git("add", "CHANGELOG.md")
    return if git("diff", "--cached", "--quiet",
allow_failure: true) && git("diff", "--cached", "--name-only").strip.empty?

    git("commit", "-m", "Split the changelog into one section per retro version")
  end

  #: (*untyped, **untyped) -> untyped
  def self.verify(ref)
    text = File.read(TABLE)
    entries = plan(ref, text)
    problems = entries.flat_map { |entry| tag_problems(entry) }
    problems += entries.reject { |entry| gh("release", "view", entry[:version].to_s, allow_failure: true) }
                       .map { |entry| "GitHub Release #{entry[:version]} is missing" }
    changelog = File.read("CHANGELOG.md")
    problems += entries.reject { |entry|
 changelog.include?(entry[:notes]) }.map { |entry| "CHANGELOG.md lacks the section #{entry[:version]}" }
    majors = rows(text).count { |row| row[9] == "major" }
    major = entries.last[:version].major
    problems << "major number #{major} is not #{majors}" unless major == majors
    puts(problems.empty? ? "retro verified: #{entries.size} versions" : problems)
    exit(problems.empty? ? 0 : 1)
  end

  #: (*untyped, **untyped) -> untyped
  def self.tag_problems(entry)
    tag = entry[:version].to_s
    found = git("rev-parse", "--verify", "-q", "refs/tags/#{tag}^{commit}", allow_failure: true).strip
    found == entry[:sha] ? [] : [ "tag #{tag} is #{found.empty? ? 'missing' : found[0,
7]}, expected #{entry[:sha][0, 7]}" ]
  end
end

if $PROGRAM_NAME == __FILE__
  ref = "origin/main"
  Retro.git("fetch", "origin", "main")
  case ARGV.first
  when "table" then Retro.table(ref)
  when "apply" then Retro.apply(ref, ARGV.include?("--execute"))
  when "verify" then Retro.verify(ref)
  else abort "usage: retro.rb table|apply|verify"
  end
end
