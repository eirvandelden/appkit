class ApplicationController < ActionController::Base
  include Appkit::Authentication
  include Appkit::VersionHeaders
end
