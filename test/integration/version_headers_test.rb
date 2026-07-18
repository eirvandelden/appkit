require "test_helper"

class VersionHeadersTest < ActionDispatch::IntegrationTest
  test "responses include X-Version and X-Rev from the host app's config" do
    sign_in_as users(:alice)

    get root_url

    assert_equal Rails.application.config.app_version, response.headers["X-Version"]
    assert_equal Rails.application.config.git_revision, response.headers["X-Rev"]
  end
end
