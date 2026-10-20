require "rails/generators"
require "rails/generators/migration"

module Appkit
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include Rails::Generators::Migration

      # __dir__ is nil only inside eval, which never loads this file.
      source_root File.expand_path("templates", __dir__) # steep:ignore ArgumentTypeMismatch

      ERROR_PAGES = %w[
        404.html
        406-unsupported-browser.html
        422.html
        500.html
        502.html
      ].freeze #: Array[String]

      APPLICATION_CONTROLLER = "app/controllers/application_controller.rb" #: String
      AUTHENTICATION_INCLUDE = /^\s*include\s+Appkit::Authentication\b/ #: Regexp

      #: (String) -> String
      def self.next_migration_number(dirname)
        # current_migration_number comes from Rails generators, which the railties RBS does not describe.
        next_number = current_migration_number(dirname) + 1 # steep:ignore NoMethod
        # next_migration_number comes from Rails generators, which the railties RBS does not describe.
        ActiveRecord::Migration.next_migration_number(next_number) # steep:ignore NoMethod
      end

      #: () -> void
      def create_sessions_migration
        if sessions_table_exists?
          migration_template "align_sessions.rb.tt", "db/migrate/align_sessions_for_appkit.rb"
        else
          migration_template "create_sessions.rb.tt", "db/migrate/create_sessions.rb"
        end
      end

      #: () -> void
      def create_push_subscriptions_migration
        migration_template "create_appkit_push_subscriptions.rb.tt", "db/migrate/create_appkit_push_subscriptions.rb"
      end

      #: () -> void
      def add_authentication_to_application_controller
        return unless File.exist?(application_controller_file)
        return if File.read(application_controller_file).match?(AUTHENTICATION_INCLUDE)

        # inject_into_class comes from Rails generators, which the railties RBS does not describe.
        # steep:ignore:start
        inject_into_class APPLICATION_CONTROLLER, "ApplicationController", "  include Appkit::Authentication\n"
        # steep:ignore:end
      end

      #: () -> void
      def copy_error_pages
        # copy_file comes from Rails generators, which the railties RBS does not describe.
        ERROR_PAGES.each { |page| copy_file "public/#{page}", "public/#{page}" } # steep:ignore NoMethod
      end

      #: () -> void
      def copy_ci_workflow
        # template comes from Rails generators, which the railties RBS does not describe.
        template "github/workflows/ci.yml.tt", ".github/workflows/ci.yml" # steep:ignore NoMethod
      end

      private
        #: () -> bool
        def sessions_table_exists?
          ActiveRecord::Base.connection.table_exists?(:sessions)
        rescue ActiveRecord::NoDatabaseError, ActiveRecord::ConnectionNotEstablished
          false
        end

        #: () -> String
        def application_controller_file
          # destination_root comes from Rails generators, which the railties RBS does not describe.
          File.join(destination_root, APPLICATION_CONTROLLER) # steep:ignore NoMethod
        end
    end
  end
end
