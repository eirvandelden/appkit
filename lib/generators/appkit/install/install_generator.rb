require "rails/generators"
require "rails/generators/migration"

module Appkit
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include Rails::Generators::Migration

      source_root File.expand_path("templates", __dir__)

      def self.next_migration_number(dirname)
        next_number = current_migration_number(dirname) + 1
        ActiveRecord::Migration.next_migration_number(next_number)
      end

      def create_sessions_migration
        if sessions_table_exists?
          migration_template "align_sessions.rb.tt", "db/migrate/align_sessions_for_appkit.rb"
        else
          migration_template "create_sessions.rb.tt", "db/migrate/create_sessions.rb"
        end
      end

      private
        def sessions_table_exists?
          ActiveRecord::Base.connection.table_exists?(:sessions)
        rescue ActiveRecord::NoDatabaseError, ActiveRecord::ConnectionNotEstablished
          false
        end
    end
  end
end
