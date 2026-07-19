require "test_helper"

class SessionBehaviorTest < ActiveSupport::TestCase
  test "start! creates a session with a unique token and last_active_at set" do
    session = users(:alice).sessions.start!(user_agent: "Mozilla/5.0", ip_address: "127.0.0.1")

    assert session.persisted?
    assert session.token.present?
    assert session.last_active_at.present?
  end

  test "token must be unique" do
    session = Session.new(user: users(:alice), token: sessions(:alice_session).token)

    session.valid?

    assert_includes session.errors.attribute_names, :token
  end

  test "before_validation defaults last_active_at when blank" do
    session = Session.new(user: users(:alice))

    session.valid?

    assert session.last_active_at.present?
  end

  test "resume refreshes last_active_at once the activity refresh rate has elapsed" do
    session = sessions(:bob_session)
    previous_last_active_at = session.last_active_at

    session.resume(user_agent: "Mozilla/5.0 (Updated)", ip_address: "10.0.0.1")

    assert session.last_active_at > previous_last_active_at
    assert_equal "10.0.0.1", session.ip_address
  end

  test "resume is a no-op within the activity refresh rate" do
    session = users(:alice).sessions.start!(user_agent: "Mozilla/5.0", ip_address: "127.0.0.1")
    previous_last_active_at = session.last_active_at
    previous_ip_address = session.ip_address

    session.resume(user_agent: "Mozilla/5.0 (Updated)", ip_address: "10.0.0.1")

    assert_equal previous_last_active_at, session.reload.last_active_at
    assert_equal previous_ip_address, session.ip_address
  end

  test "expire_stale! destroys sessions idle past the configured expiry" do
    stale = sessions(:bob_session)
    stale.update!(last_active_at: (Appkit.config.session_expiry + 1.day).ago)

    Session.expire_stale!

    assert_raises(ActiveRecord::RecordNotFound) { stale.reload }
  end

  test "expire_stale! leaves sessions within the configured expiry alone" do
    fresh = sessions(:bob_session)
    fresh.update!(last_active_at: (Appkit.config.session_expiry - 1.day).ago)

    Session.expire_stale!

    assert fresh.reload.persisted?
  end

  test "expire_stale! respects a configured session_expiry override" do
    session = sessions(:bob_session)
    session.update!(last_active_at: 8.days.ago)

    with_session_expiry(7.days) { Session.expire_stale! }

    assert_raises(ActiveRecord::RecordNotFound) { session.reload }
  end

  private
    def with_session_expiry(duration)
      original = Appkit.config.session_expiry
      Appkit.config.session_expiry = duration
      yield
    ensure
      Appkit.config.session_expiry = original
    end
end
