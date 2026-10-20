module Appkit
  # @rbs module-self ::ActionController::Base
  module Authentication
    extend ActiveSupport::Concern
    include Appkit::Authentication::SessionLookup

    SESSION_COOKIE_LIFETIME = 1.year #: ActiveSupport::Duration

    # Rails class macros run on the including class; the available RBS does not describe them.
    # steep:ignore:start
    included do
      before_action :require_authentication
      helper_method :signed_in?
    end
    # steep:ignore:end

    module ClassMethods
      #: (**untyped) -> void
      def require_unauthenticated_access(**options)
        allow_unauthenticated_access(**options)
        # before_action is a controller macro that the available RBS does not describe on a singleton.
        before_action :redirect_signed_in_user_to_root, **options # steep:ignore NoMethod
      end

      #: (**untyped) -> void
      def allow_unauthenticated_access(**options)
        # skip_before_action is a controller macro that the available RBS does not describe on a singleton.
        skip_before_action :require_authentication, **options # steep:ignore NoMethod
        # before_action is a controller macro that the available RBS does not describe on a singleton.
        before_action :restore_authentication, **options # steep:ignore NoMethod
      end
    end

    private
      #: () -> bool
      def signed_in?
        # Current is owned by the host app, so the shipped signatures cannot name it.
        Current.user.present? # steep:ignore UnknownConstant
      end

      #: () -> untyped
      def require_authentication
        restore_authentication || request_authentication
      end

      #: () -> untyped
      def restore_authentication
        if session = find_session_by_cookie
          resume_session session
        end
      end

      #: () -> void
      def request_authentication
        session[:return_to_after_authenticating] = request.url
        # new_session_url is a route helper, defined by the host app's routes.
        redirect_to new_session_url # steep:ignore NoMethod
      end

      #: () -> void
      def redirect_signed_in_user_to_root
        # root_url is a route helper, defined by the host app's routes.
        redirect_to root_url if signed_in? # steep:ignore NoMethod
      end

      #: (untyped) -> untyped
      def start_new_session_for(user)
        user.sessions.start!(user_agent: request.user_agent, ip_address: request.remote_ip).tap do |session|
          authenticated_as session
        end
      end

      #: (untyped) -> untyped
      def resume_session(session)
        session.resume user_agent: request.user_agent, ip_address: request.remote_ip
        authenticated_as session
      end

      # Fix vs JA: also tracks the session record on Current, not just the user.
      #: (untyped) -> untyped
      def authenticated_as(session)
        # Current is owned by the host app, so the shipped signatures cannot name it.
        Current.user = session.user # steep:ignore UnknownConstant
        # Current is owned by the host app, so the shipped signatures cannot name it.
        Current.session = session # steep:ignore UnknownConstant
        set_authenticated_by(:session)
        cookies.signed[:session_token] = {
          value: session.token,
          httponly: true,
          secure: Rails.env.production?,
          same_site: :lax,
          expires: SESSION_COOKIE_LIFETIME.from_now
        }
      end

      #: () -> String
      def post_authenticating_url
        # root_url is a route helper, defined by the host app's routes.
        session.delete(:return_to_after_authenticating) || root_url # steep:ignore NoMethod
      end

      # Fix vs JA: destroys the Session row so rows don't accumulate forever.
      #: () -> untyped
      def reset_authentication
        find_session_by_cookie&.destroy
        cookies.delete(:session_token)
      end

      #: (Symbol) -> ActiveSupport::StringInquirer
      def set_authenticated_by(method)
        @authenticated_by = method.to_s.inquiry
      end

      #: () -> ActiveSupport::StringInquirer
      def authenticated_by
        @authenticated_by ||= "".inquiry
      end
  end
end
