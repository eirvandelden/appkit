# Steep checks the generated sig/ (what ships in the gem) against app/ and lib/.
# Regenerate it first with `bundle exec rake rbs:generate`.
target :appkit do
  signature "sig"

  check "app"
  check "lib"
end
