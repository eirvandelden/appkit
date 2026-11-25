module Semver
  # The repo-specific part of a release: which files carry the version and the changelog.
  module Stamp
    VERSION_FILE = "lib/appkit/version.rb" #: String
    CHANGELOG = "CHANGELOG.md" #: String

    #: (version: Version, notes: String, fragments: Array[Fragment]) -> Array[String]
    def self.apply(version:, notes:, fragments:)
      write_version(version)
      write_changelog(notes)
      removed = fragments.filter_map(&:path).each { |path| File.delete(path) }
      [ VERSION_FILE, CHANGELOG, *removed ]
    end

    #: (Version) -> void
    def self.write_version(version)
      text = File.read(VERSION_FILE).sub(/VERSION = "[^"]*"/, %(VERSION = "#{version}"))
      File.write(VERSION_FILE, text)
    end

    #: (String) -> void
    def self.write_changelog(notes)
      text = File.read(CHANGELOG)
      index = text.index(/^## /) || text.length
      File.write(CHANGELOG, "#{text[0...index]}#{notes}\n#{text[index..]}")
    end
  end
end
