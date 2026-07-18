require_relative "lib/appkit/version"

Gem::Specification.new do |spec|
  spec.name          = "appkit"
  spec.version       = Appkit::VERSION
  spec.authors       = ["Etienne van Delden"]
  spec.email         = ["etienne@conductor.build"]
  spec.homepage      = "https://github.com/eirvandelden/appkit"
  spec.summary       = "Appkit - auth, PWA/push, and theme/preferences toolkit for Rails apps"
  spec.description   = "A non-isolated Rails engine providing session-based authentication, " \
                        "PWA installability with web push notifications, and theme/preferences " \
                        "management for host Rails applications."
  spec.license       = "osaassy"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,lib}/**/*", "LICENSE.md", "README.md", "CHANGELOG.md"]
  end

  spec.add_dependency "railties", ">= 8.0"
  spec.add_dependency "web-push", "~> 3.0"
  spec.add_dependency "turbo-rails", ">= 2.0"

  spec.add_development_dependency "rails", ">= 8.0"
  spec.add_development_dependency "sqlite3"
  spec.add_development_dependency "bcrypt"
  spec.add_development_dependency "propshaft"
end
