module Appkit
  # The host's ApplicationController, which includes Appkit::Authentication, is the real superclass.
  # @rbs inherits ::ActionController::Base
  class QrCodeController < ApplicationController # steep:ignore UnknownConstant
    # @rbs!
    #   include ::Appkit::Authentication
    #   extend ::Appkit::Authentication::ClassMethods

    allow_unauthenticated_access

    rescue_from ActiveSupport::MessageVerifier::InvalidSignature, with: :respond_not_found

    #: () -> void
    def show
      qr_code_link = Appkit::QrCodeLink.from_signed(params[:id])
      svg = RQRCode::QRCode.new(qr_code_link.url).as_svg(viewbox: true, fill: :white, color: :black)

      expires_in 1.year, public: true
      render plain: svg, content_type: "image/svg+xml"
    end

    private

    #: () -> void
    def respond_not_found
      head :not_found
    end
  end
end
