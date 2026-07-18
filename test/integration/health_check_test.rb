require "test_helper"

class HealthCheckTest < ActionDispatch::IntegrationTest
  setup { SolidQueue::Process.delete_all }

  test "/all returns 200 when DB, cache, and queue are all healthy" do
    create_process_with_heartbeat(1.minute.ago)

    get "/status/all"

    assert_response :success
  end

  test "/all returns 500 when no Solid Queue process has a recent heartbeat" do
    get "/status/all"

    assert_response :internal_server_error
  end

  test "/all returns 500 when the only Solid Queue process heartbeat is stale" do
    create_process_with_heartbeat(1.hour.ago)

    get "/status/all"

    assert_response :internal_server_error
  end

  test "the dummy app's configured health_check_path mounts the endpoint, not the gem's own default" do
    get "/status"

    assert_response :success
  end

  private

  def create_process_with_heartbeat(heartbeat_at)
    SolidQueue::Process.create!(
      kind: "Worker",
      last_heartbeat_at: heartbeat_at,
      pid: 1,
      name: "worker-#{SecureRandom.hex(4)}",
      created_at: Time.current
    )
  end
end
