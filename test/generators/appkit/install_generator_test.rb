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

      test "adds include Appkit::Authentication to an ApplicationController that lacks it" do
        write_application_controller

        run_generator

        assert_file "app/controllers/application_controller.rb", /^  include Appkit::Authentication$/
      end

      test "running the generator twice leaves one include Appkit::Authentication" do
        write_application_controller

        2.times { run_generator }

        assert_equal 1, application_controller.scan("include Appkit::Authentication").size
      end

      test "leaves an ApplicationController that already includes Appkit::Authentication unchanged" do
        write_application_controller "class ApplicationController < ActionController::Base\n    include  Appkit::Authentication\nend\n"

        assert_no_changes -> { application_controller } do
          run_generator
        end
      end

      test "skips the include when the host has no ApplicationController" do
        run_generator

        assert_no_file "app/controllers/application_controller.rb"
      end

      test "adds the include when run with --skip" do
        write_application_controller

        run_generator %w[--skip]

        assert_file "app/controllers/application_controller.rb", /^  include Appkit::Authentication$/
      end

      private
        def write_application_controller(content = "class ApplicationController < ActionController::Base\nend\n")
          path = File.join(destination_root, "app/controllers/application_controller.rb")
          FileUtils.mkdir_p File.dirname(path)
          File.write path, content
        end

        def application_controller
          File.read File.join(destination_root, "app/controllers/application_controller.rb")
        end

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
