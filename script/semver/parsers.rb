module Semver
  # Pure functions: file text in, a Hash of fact => detail out. No git, no IO.
  module Parsers
    ROUTE_VERBS = %w[get post patch put delete].freeze #: Array[String]
    ROUTE_RESOURCE = /\A(resources?)\s+(:\w+)(.*?)(\s+do(\s*\|.*\|)?)?\z/ #: Regexp
    RESOURCE_ACTIONS = {
      "resource" => %w[show new create edit update destroy],
      "resources" => %w[index show new create edit update destroy]
    }.freeze #: Hash[String, Array[String]]
    ROUTE_IDENTITY = %w[as path path_names param constraints].freeze #: Array[String]
    ROUTE_VERB = /\A(#{ROUTE_VERBS.join('|')})\s+["']([^"']+)["']\s*(.*?)(\s+do)?\z/ #: Regexp

    #: (String) -> Hash[String, String]
    def self.config_options(text)
      names = text.scan(/^\s*attr_accessor\s+:(\w+)/).flatten
      names.zip(names.map { |name| text.match?(/^\s*@#{name}\s*=/) ? "has_default" : "no_default" }).to_h
    end

    #: (String) -> Hash[String, String]
    def self.routes(text)
      facts = {} #: Hash[String, String]
      stack = [] #: Array[String?]
      text.each_line(chomp: true) do |raw|
        line = raw.strip
        next if line.empty? || line.start_with?("#") || line.start_with?("Rails.application.routes.draw")

        next stack.pop if line == "end"

        key, detail, opens = route_fact(line)
        path = [ *stack.compact, key ].join(" > ")
        facts[path] = route_identity(detail)
        route_actions(key, detail).each { |action| facts["#{path}##{action}"] = "" }
        stack << key if opens
        stack << nil if opens.nil? && key.start_with?("unparsed:") && line.match?(/\bdo\b/)
      end
      facts
    end

    # The actions a resource exposes, from its only: and except: options.
    #: (String, String) -> Array[String]
    def self.route_actions(key, detail)
      kind = key[/\Aresources?\b/] or return []
      return route_action_list("only", detail) if detail.match?(/\bonly:/)

      RESOURCE_ACTIONS.fetch(kind) - route_action_list("except", detail)
    end

    # The actions of one option. A list this parser cannot read becomes an unparsed action, never an empty list.
    #: (String, String) -> Array[String]
    def self.route_action_list(option, detail)
      return [] unless detail.match?(/\b#{option}:/)

      list = detail[/\b#{option}:\s*(%[iw]\[[^\]]*\]|\[[^\]]*\]|:\w+)/, 1]
      return [ "unparsed:#{option} #{detail[/\b#{option}:\s*([^,]+)/, 1].to_s.strip}" ] unless list

      list.delete_prefix("%i").delete_prefix("%w").scan(/\w+/)
    end

    # The options that name a route: its helper name, its URL and the constraints on it.
    # The actions are facts of their own, and the controller is no part of what an app sees.
    #: (String) -> String
    def self.route_identity(detail)
      options = detail.scan(/\b(#{ROUTE_IDENTITY.join('|')}):\s*(%[iw]\[[^\]]*\]|\{[^}]*\}|"[^"]*"|'[^']*'|[^,\s]+)/)
      options.sort.map { |name, value| "#{name}: #{value}" }.join(", ")
    end

    #: (String) -> Array[untyped]
    def self.route_fact(line)
      if (match = ROUTE_RESOURCE.match(line))
        [ "#{match[1]} #{match[2]}", match[3].to_s.strip, match[4] ? true : false ]
      elsif (match = ROUTE_VERB.match(line))
        [ "#{match[1].upcase} /#{match[2].delete_prefix('/')}", match[3].to_s.strip, match[4] ? true : false ]
      elsif line.start_with?("root ")
        [ "root", line.delete_prefix("root ").strip, false ]
      else
        [ "unparsed:#{line}", line, nil ]
      end
    end

    #: (String) -> Hash[String, String]
    def self.rbs(text)
      facts = {} #: Hash[String, String]
      scope = [] #: Array[Hash[Symbol, untyped]]
      text.each_line(chomp: true) { |raw| rbs_line(raw.strip, scope, facts) }
      facts
    end

    #: (String, Array[Hash[Symbol, untyped]], Hash[String, String]) -> void
    def self.rbs_line(line, scope, facts)
      return if line.empty? || line.start_with?("#")

      current = scope.last
      case line
      when /\A(class|module|interface)\s+(\S+)(.*)\z/
        declared = Regexp.last_match(2)
        name = qualified(declared, current)
        scope.push({ name: name, private: false })
        facts[name] = line
      when "end" then scope.pop
      when "private" then current[:private] = true if current
      when "public" then current[:private] = false if current
      when /\A\|/ then facts[current[:last]] =
"#{facts[current[:last]]} #{line}" if current && !current[:private] && current[:last]
      when /\A(include|extend)\s+(.+)\z/ then facts["#{current&.fetch(:name)} #{line}"] = "" if current
      else rbs_member(line, current, facts)
      end
    end

    #: (String, Hash[Symbol, untyped]?) -> String
    def self.qualified(declared, current)
      return declared.delete_prefix("::") if current.nil? || declared.start_with?("::")

      "#{current[:name]}::#{declared}"
    end

    #: (String, Hash[Symbol, untyped]?, Hash[String, String]) -> void
    def self.rbs_member(line, current, facts)
      return if current.nil? || current[:private]

      owner = current[:name]
      case line
      when /\Adef\s+self\.(\S+?):\s*(.*)\z/ then member(current, facts, "#{owner}.#{Regexp.last_match(1)}",
Regexp.last_match(2))
      when /\Adef\s+(\S+?):\s*(.*)\z/ then member(current, facts, "#{owner}##{Regexp.last_match(1)}",
Regexp.last_match(2))
      when /\Aattr_\w+\s+(\w+):\s*(.*)\z/ then facts["#{owner}##{Regexp.last_match(1)}"] = line
      when /\A([A-Z]\w*):\s*(.*)\z/ then facts["#{owner}::#{Regexp.last_match(1)}"] = Regexp.last_match(2)
      end
    end

    #: (Hash[Symbol, untyped], Hash[String, String], String, String) -> void
    def self.member(current, facts, key, signature)
      facts[key] = signature
      current[:last] = key
    end

    #: (String) -> Hash[String, String]
    def self.gemspec_runtime(text)
      text.scan(/^\s*\w+\.add_dependency\s+(.+)$/).flatten.to_h do |args|
        name, *requirements = args.scan(/["']([^"']+)["']/).flatten
        [ name, requirements.join(", ") ]
      end
    end

    #: (String) -> Hash[String, String]
    def self.workflow_inputs(text)
      document = YAML.safe_load(text) || {}
      trigger = document["on"] || document[true] || {}
      call = trigger.is_a?(Hash) ? trigger["workflow_call"] || {} : {}
      facts = {} #: Hash[String, String]
      (call["inputs"] || {}).each do |name, spec|
        facts["input:#{name}"] = spec["required"] ? "required" : "optional"
        facts["inputtype:#{name}"] = spec["type"].to_s
      end
      (call["secrets"] || {}).each { |name, spec|
 facts["secret:#{name}"] = (spec || {})["required"] ? "required" : "optional" }
      workflow_permissions(document, facts)
      text.lines.map { |line| line.sub(/(\A|\s)#.*/, "") }.join.scan(%r{\bbin/[\w-]+}).uniq.each { |bin|
        facts["bin:#{bin}"] = ""
      }
      facts
    end

    #: (Hash[untyped, untyped], Hash[String, String]) -> void
    def self.workflow_permissions(document, facts)
      permission_facts(document["permissions"], "permission:", facts)
      (document["jobs"] || {}).each { |job, spec| permission_facts(spec["permissions"], "permission:#{job}:", facts) }
    end

    #: (untyped, String, Hash[String, String]) -> void
    def self.permission_facts(scope, prefix, facts)
      case scope
      when Hash then scope.each { |name, value| facts["#{prefix}#{name}"] = value.to_s }
      when String then facts["#{prefix}all"] = scope
      end
    end

    #: (String) -> Hash[String, String]
    def self.importmap_pins(text)
      pins = text.scan(/^\s*pin(?:_all_from)?\s+["']([^"']+)["']([^\n]*)/)
      pins.to_h { |name, options| [ importmap_key(name, options), importmap_target(options) ] }
    end

    #: (String, String) -> String
    def self.importmap_key(name, options)
      under = options[/\bunder:\s*["']([^"']+)["']/, 1]
      [ name, ("under:#{under}" if under) ].compact.join(" ")
    end

    #: (String) -> String
    def self.importmap_target(options)
      options[/\bto:\s*["']([^"']+)["']/, 1].to_s
    end

    #: (String) -> Hash[String, String]
    def self.locale_keys(text)
      flatten_locale(YAML.safe_load(text) || {}, nil, {})
    rescue Psych::Exception
      { "unparsed:yaml" => text }
    end

    #: (untyped, String?, Hash[String, String]) -> Hash[String, String]
    def self.flatten_locale(node, prefix, facts)
      return facts.merge!(prefix.to_s => node.to_s) unless node.is_a?(Hash)

      node.each { |key, value| flatten_locale(value, [ prefix, key ].compact.join("."), facts) }
      facts
    end

    #: (String) -> Hash[String, String]
    def self.template_files(text)
      { "content" => Digest::SHA256.hexdigest(text) }
    end

    private_class_method :route_actions, :route_action_list, :route_identity, :route_fact, :rbs_line,
                         :qualified, :rbs_member, :member, :workflow_permissions, :permission_facts,
                         :importmap_key, :importmap_target, :flatten_locale
  end
end
