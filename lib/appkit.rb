require "rqrcode"
require "web_push"
require "okcomputer"
require "appkit/version"
require "appkit/revision"
require "appkit/configuration"
require "appkit/ok_computer/solid_queue_check"
require "appkit/engine" if defined?(Rails)

module Appkit
  #: () -> Configuration
  def self.config
    @config ||= Configuration.new
  end

  #: () -> String
  def self.revision
    @revision ||= Revision.new(spec: Gem.loaded_specs["appkit"]).to_s
  end

  #: () { (Configuration) -> void } -> void
  def self.configure
    yield config
  end
end
