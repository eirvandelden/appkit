require_relative "semver_test_helper"

class ParsersTest < ActiveSupport::TestCase
  P = Semver::Parsers

  def test_config_options_mark_defaults
    text = "attr_accessor :a\nattr_accessor :b\ndef initialize\n  @b = 1\nend\n"

    assert_equal({ "a" => "no_default", "b" => "has_default" }, P.config_options(text))
  end

  def test_routes_nest_resources_and_read_verbs
    text = [ "Rails.application.routes.draw do", "  resource :session, only: :new do",
             "    resources :transfers", "  end", "  get \"manifest\" => \"pwa#m\"", "end", "" ].join("\n")
    keys = P.routes(text).keys.reject { |key| key.include?("#") }

    assert_equal [ "resource :session", "resource :session > resources :transfers", "GET /manifest" ], keys
  end

  def test_routes_list_the_actions_a_resource_exposes
    only = P.routes("resource :session, only: %i[new create destroy]\n").keys
    default = P.routes("resources :things, except: :destroy\n").keys

    assert_includes only, "resource :session#destroy"
    assert_not_includes only, "resource :session#show"
    assert_includes default, "resources :things#index"
    assert_not_includes default, "resources :things#destroy"
  end

  def test_unknown_routes_dsl_is_unparsed_fact
    facts = P.routes("Rails.application.routes.draw do\n  mount Foo => \"/foo\"\nend\n")

    assert_equal [ "unparsed:mount Foo => \"/foo\"" ], facts.keys
  end

  def test_rbs_reads_methods_attrs_constants_and_skips_private
    text = [ "module A", "  class B", "    X: Integer", "    attr_reader y: String", "    def self.make: () -> B",
             "    def go: (Integer) -> void", "    private", "    def hidden: () -> void", "  end", "end",
             "" ].join("\n")
    facts = P.rbs(text)

    assert_equal "(Integer) -> void", facts["A::B#go"]
    assert_equal "() -> B", facts["A::B.make"]
    assert_equal "Integer", facts["A::B::X"]
    assert_includes facts.keys, "A::B#y"
    assert_includes facts.keys, "A::B"
    assert_not_includes facts.keys, "A::B#hidden"
  end

  def test_rbs_absolute_class_name_ignores_the_enclosing_scope
    assert_includes Semver::Parsers.rbs("module A\n  class ::A::B\n    def go: () -> void\n  end\nend\n").keys, "A::B#go"
  end

  def test_rbs_nested_classes_are_named_once
    facts = P.rbs("module A\n  class B\n    class C\n      def go: () -> void\n    end\n  end\nend\n")

    assert_includes facts.keys, "A::B::C#go"
    assert_not_includes facts.keys, "A::A::B::C#go"
  end

  def test_rbs_overload_lines_belong_to_their_method
    text = "class A\n  def go: (String) -> void\n    | (Integer) -> void\nend\n"
    changed = "class A\n  def go: (String) -> void\n    | (Symbol) -> void\nend\n"

    assert_not_equal P.rbs(text)["A#go"], P.rbs(changed)["A#go"]
  end

  def test_rbs_public_ends_private
    facts = P.rbs("class A\n  private\n  def a: () -> void\n  public\n  def b: () -> void\nend\n")

    assert_not_includes facts.keys, "A#a"
    assert_includes facts.keys, "A#b"
  end

  def test_gemspec_runtime_ignores_development_dependencies
    text = "spec.add_dependency \"rails\", \"~> 8.1\"\nspec.add_development_dependency \"rake\"\n"

    assert_equal({ "rails" => "~> 8.1" }, P.gemspec_runtime(text))
  end

  def test_workflow_inputs_secrets_permissions_and_bins
    text = [ "on:", "  workflow_call:", "    inputs:", "      a:", "        required: true", "    secrets:", "      s:",
             "        required: true", "permissions:", "  contents: read", "jobs:", "  j:", "    steps:",
             "      - run: bin/rails test", "" ].join("\n")
    facts = P.workflow_inputs(text)

    assert_equal "required", facts["input:a"]
    assert_equal "required", facts["secret:s"]
    assert_equal "read", facts["permission:contents"]
    assert_includes facts.keys, "bin:bin/rails"
  end

  def test_workflow_input_types_are_facts
    text = "on:\n  workflow_call:\n    inputs:\n      a:\n        type: boolean\n        default: true\n"

    assert_equal "boolean", P.workflow_inputs(text)["inputtype:a"]
  end

  def test_workflow_comments_are_not_bin_facts
    text = "# run bin/old to see\njobs:\n  j:\n    steps:\n      - run: bin/rails test # not bin/other\n"
    facts = P.workflow_inputs(text)

    assert_equal [ "bin:bin/rails" ], facts.keys.grep(/\Abin:/)
  end

  def test_importmap_pins
    assert_equal({ "a" => "a.js" }, P.importmap_pins("pin \"a\", to: \"a.js\"\n"))
  end

  def test_locale_keys_flatten
    assert_equal({ "en.a.b" => "x" }, P.locale_keys("en:\n  a:\n    b: x\n"))
  end

  def test_template_files_digest_changes_with_content
    assert_not_equal P.template_files("a"), P.template_files("b")
  end

  test "the semver code needs the standard library only" do
    script = File.expand_path("../../script", __dir__)
    code = "require 'semver'; Semver::Parsers.config_options(\"attr_accessor :a\\n\"); Semver::Rules::ALL"
    _out, err, status = Open3.capture3(RbConfig.ruby, "-I", script, "-e", code)

    assert_predicate status, :success?, err
  end
end
