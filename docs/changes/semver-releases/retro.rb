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

  # CHANGELOG.md text per unit, by blaming the baseline file: each final line goes to the unit that introduced it.
  #: (*untyped, **untyped) -> untyped
  def self.changelog_sections(ref, baseline_sha, units)
    text = git("show", "#{ref}:CHANGELOG.md").lines
    owners = blame(ref)
    positions = chain(ref).each_with_index.to_h { |(sha, *), index| [ sha, index ] }
    boundaries = [ positions.fetch(baseline_sha), *units.map(&:tip_index) ]
    sections = Array.new(boundaries.size) { Hash.new { |hash, key| hash[key] = [] } }
    heading = nil
    text.each_with_index do |line, index|
      heading = line[/\A### (.+)/, 1] || heading
      next if line.start_with?("#") || line.strip.empty? || heading.nil?

      slot = boundaries.index { |boundary| positions.fetch(owners.fetch(index)) <= boundary }
      raise "line #{index + 1} of CHANGELOG.md is newer than the last merge" unless slot

      sections[slot][heading] << line.chomp
    end
    sections
  end

  #: (*untyped, **untyped) -> untyped
  def self.blame(ref)
    owners = []
    git("blame", "--first-parent", "--porcelain", ref, "--", "CHANGELOG.md").each_line do |line|
      owners << line.split.first if line.match?(/\A\h{40} \d+ \d+/)
    end
    owners
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

  #: (*untyped, **untyped) -> untyped
  def self.publish(entries)
    entries.each { |entry| git("tag", entry[:version].to_s, entry[:sha]) }
    git("push", "origin", *entries.map { |entry| "refs/tags/#{entry[:version]}" })
    entries.each do |entry|
      Open3.capture3("gh", "release", "create", entry[:version].to_s, "--title", entry[:version].to_s, "--verify-tag",
                     "--notes", entry[:notes].sub(/\A.*?\n\n/m, ""))
    end
    entries.group_by { |entry| entry[:version].major }.each_value do |group|
      newest = group.last[:version]
      git("tag", "-f", newest.major_tag, newest.to_s)
      git("push", "--force", "origin", "refs/tags/#{newest.major_tag}")
    end
  end

  #: (*untyped, **untyped) -> untyped
  def self.rewrite_changelog(entries)
    current = File.read("CHANGELOG.md")
    header = current[0...(current.index(/^## /) || current.length)]
    File.write("CHANGELOG.md", header + entries.reverse.map { |entry| entry[:notes] }.join("\n"))
    git("add", "CHANGELOG.md")
    git("commit", "-m", "Split the changelog into one section per retro version")
  end

  #: (*untyped, **untyped) -> untyped
  def self.verify(ref)
    text = File.read(TABLE)
    entries = plan(ref, text)
    problems = entries.flat_map { |entry| tag_problems(entry) }
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

ref = "origin/main"
Retro.git("fetch", "origin", "main")
case ARGV.first
when "table" then Retro.table(ref)
when "apply" then Retro.apply(ref, ARGV.include?("--execute"))
when "verify" then Retro.verify(ref)
else abort "usage: retro.rb table|apply|verify"
end
