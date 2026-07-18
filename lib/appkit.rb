require "rqrcode"
require "web_push"
require "okcomputer"
require "appkit/version"
require "appkit/configuration"
require "appkit/ok_computer/solid_queue_check"
require "appkit/engine" if defined?(Rails)

module Appkit
  def self.config
    @config ||= Configuration.new
  end

  def self.configure
    yield config
  end
end
