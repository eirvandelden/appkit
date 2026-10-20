require "active_support/core_ext/enumerable"
require "fileutils"
require "tmpdir"

# Deletes only the generated files: sig/manifest.yaml is hand-written.
GENERATE_SIG = [
  "find sig -name '*.rbs' -delete",
  "bundle exec rbs-inline --opt-out --output=sig app lib"
].freeze

module GeneratedSignatures
  def self.copy(from:, to:)
    Dir.glob("**/*.rbs", base: from).each do |path|
      FileUtils.mkdir_p(File.dirname(File.join(to, path)))
      FileUtils.cp(File.join(from, path), File.join(to, path))
    end
  end
end

namespace :rbs do
  desc "Regenerate sig/ from the inline #: signatures"
  task :generate do
    GENERATE_SIG.each { |command| sh command }
  end

  desc "Fail when sig/ differs from what the inline #: signatures generate"
  task check: :generate do
    # Compare before anything touches the index, so a deleted signature shows in the diff.
    sh "git diff --exit-code -- sig/"
    untracked = `git ls-files --others --exclude-standard -- sig/`
    abort "sig/ has generated files that git does not hold:\n#{untracked}" unless untracked.empty?
  end

  desc "Fail when the staged sig/ differs from what the staged inline #: signatures generate"
  task :check_staged do
    Dir.mktmpdir("appkit-staged") do |dir|
      sh "git checkout-index --all --prefix=#{dir}/"
      FileUtils.mkdir_p(File.join(dir, "sig"))
      FileUtils.cp_r(File.join(dir, "sig"), File.join(dir, "sig.staged"))
      GENERATE_SIG.each { |command| sh command, chdir: dir }
      next if system("diff", "-ru", "sig.staged", "sig", chdir: dir)

      # Copy what the staged files generate, so a partial commit can pass once this is staged.
      sh "find sig -name '*.rbs' -delete"
      GeneratedSignatures.copy(from: File.join(dir, "sig"), to: "sig")
      abort "The staged sig/ is stale. sig/ now holds what the staged files generate; stage it and commit again."
    end
  end
end

desc "Type-check app/ and lib/ with Steep, then appkit as a host app uses it"
task :steep do
  # A git hook exports GIT_DIR. rbs collection then runs its own git commands against this
  # repository and silently installs only the stdlib types, so every Rails type goes missing.
  git_env = ENV.keys.grep(/\AGIT_/).index_with(nil)
  sh git_env, "bundle exec rbs collection update"
  sh "bundle exec steep check"
  sh "bundle exec steep check --steepfile test/types/Steepfile"
end
