require "test_helper"
require "rails/generators/test_case"
require "generators/appkit/install/install_generator"

module Appkit
  module Generators
    class InstallGeneratorTest < Rails::Generators::TestCase
      tests InstallGenerator
      destination File.expand_path("../../../tmp/install_generator", __dir__)
      setup :prepare_destination

      test "creates an align_sessions migration when the sessions table already exists" do
        run_generator

        assert_migration "db/migrate/align_sessions_for_appkit.rb" do |content|
          assert_match(/change_column_null :sessions, :token, false/, content)
          assert_match(/add_column :sessions, :last_active_at, :datetime/, content)
        end
      end

      test "creates a create_sessions migration when there is no sessions table yet" do
        without_sessions_table { run_generator }

        assert_migration "db/migrate/create_sessions.rb" do |content|
          assert_match(/create_table :sessions/, content)
        end
      end

      test "creates a push_subscriptions migration" do
        run_generator

        assert_migration "db/migrate/create_appkit_push_subscriptions.rb" do |content|
          assert_match(/create_table :appkit_push_subscriptions/, content)
          assert_match(/t\.references :user, null: false, foreign_key: true/, content)
          assert_match(/add_index :appkit_push_subscriptions, :endpoint, unique: true/, content)
        end
      end

      test "copies the static error pages into the host's public directory" do
        run_generator

        InstallGenerator::ERROR_PAGES.each do |page|
          assert_file "public/#{page}"
        end
      end

      test "copies the thin CI caller workflow into the host's .github directory" do
        run_generator

        assert_file ".github/workflows/ci.yml" do |content|
          assert_match(%r{uses: eirvandelden/appkit/\.github/workflows/rails-ci\.yml@main}, content)
          assert_match(/run_system_tests: true/, content)
        end
      end

      private
        def without_sessions_table
          connection = ActiveRecord::Base.connection
          original = connection.method(:table_exists?)
          connection.define_singleton_method(:table_exists?) { |*| false }
          yield
        ensure
          connection.define_singleton_method(:table_exists?, original)
        end
    end
  end
end
