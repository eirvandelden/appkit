require "test_helper"

class ConfigurableEmailAttributeTest < ActionDispatch::IntegrationTest
  test "sessions controller honors a non-default Appkit.config.email_attribute" do
    with_email_attribute(:email_address) do
      post session_url, params: { email_address: users(:alice).email, password: "password" }

      assert_redirected_to root_url
    end
  end

  private
    def with_email_attribute(attribute)
      original = Appkit.config.email_attribute
      Appkit.config.email_attribute = attribute
      yield
    ensure
      Appkit.config.email_attribute = original
    end
end
