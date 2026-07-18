module Appkit
  class QrCodeController < ApplicationController
    allow_unauthenticated_access

    rescue_from ActiveSupport::MessageVerifier::InvalidSignature, with: -> { head :not_found }

    def show
      qr_code_link = Appkit::QrCodeLink.from_signed(params[:id])
      svg = RQRCode::QRCode.new(qr_code_link.url).as_svg(viewbox: true, fill: :white, color: :black)

      expires_in 1.year, public: true
      render plain: svg, content_type: "image/svg+xml"
    end
  end
end
