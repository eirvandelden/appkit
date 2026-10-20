namespace :rbs do
  desc "Regenerate sig/ from the inline #: signatures"
  task :generate do
    sh "find sig -name '*.rbs' -delete"
    sh "bundle exec rbs-inline --opt-out --output=sig app lib"
  end

  desc "Fail when sig/ differs from what the inline #: signatures generate"
  task check: :generate do
    sh "git add --intent-to-add sig/"
    sh "git diff --exit-code sig/"
  end
end

desc "Type-check app/ and lib/ with Steep"
task :steep do
  sh "bundle exec rbs collection update"
  sh "bundle exec steep check"
end
