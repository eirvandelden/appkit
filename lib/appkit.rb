require "rqrcode"
require "web_push"
require "appkit/version"
require "appkit/configuration"
require "appkit/engine" if defined?(Rails)

module Appkit
  def self.config
    @config ||= Configuration.new
  end

  def self.configure
    yield config
  end
end
