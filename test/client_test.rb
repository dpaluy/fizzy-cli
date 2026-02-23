# frozen_string_literal: true

require_relative "test_helper"

class ClientTest < Minitest::Test
  include TestConfig

  BASE = "https://app.fizzy.do"

  def setup
    setup_config
    @client = Fizzy::Client.new(token: "test-token", account_slug: "acme")
  end

  def teardown
    teardown_config
  end

  # --- GET ---

  def test_get_sends_correct_url_and_auth_header
    stub_request(:get, "#{BASE}/api/boards")
      .with(headers: { "Authorization" => "Bearer test-token", "Accept" => "application/json" })
      .to_return(status: 200, body: '[{"id":"1","name":"Board"}]', headers: { "Content-Type" => "application/json" })

    response = @client.get("/api/boards")

    assert_instance_of Fizzy::Response, response
    assert_equal 200, response.status
    assert_equal [{ "id" => "1", "name" => "Board" }], response.body
  end

  def test_get_with_params
    stub_request(:get, "#{BASE}/api/boards?page=2&per_page=10")
      .to_return(status: 200, body: "[]", headers: { "Content-Type" => "application/json" })

    response = @client.get("/api/boards", params: { page: 2, per_page: 10 })

    assert_equal 200, response.status
    assert_equal [], response.body
  end

  # --- POST ---

  def test_post_sends_json_body
    stub_request(:post, "#{BASE}/api/boards")
      .with(
        body: '{"name":"New Board"}',
        headers: { "Content-Type" => "application/json", "Authorization" => "Bearer test-token" }
      )
      .to_return(status: 200, body: '{"id":"2","name":"New Board"}', headers: { "Content-Type" => "application/json" })

    response = @client.post("/api/boards", body: { name: "New Board" })

    assert_equal({ "id" => "2", "name" => "New Board" }, response.body)
  end

  # --- PUT ---

  def test_put_sends_json_body
    stub_request(:put, "#{BASE}/api/boards/1")
      .with(body: '{"name":"Updated"}', headers: { "Content-Type" => "application/json" })
      .to_return(status: 200, body: '{"id":"1","name":"Updated"}', headers: { "Content-Type" => "application/json" })

    response = @client.put("/api/boards/1", body: { name: "Updated" })

    assert_equal({ "id" => "1", "name" => "Updated" }, response.body)
  end

  # --- DELETE ---

  def test_delete_request
    stub_request(:delete, "#{BASE}/api/boards/1")
      .to_return(status: 200, body: "", headers: { "Content-Type" => "application/json" })

    response = @client.delete("/api/boards/1")

    assert_equal 200, response.status
  end

  # --- 201 with Location header follow ---

  def test_201_with_location_follows_redirect
    stub_request(:post, "#{BASE}/api/cards")
      .to_return(status: 201, body: "", headers: { "Location" => "/api/cards/42.json" })

    stub_request(:get, "#{BASE}/api/cards/42")
      .to_return(status: 200, body: '{"id":"42","title":"Created"}', headers: { "Content-Type" => "application/json" })

    response = @client.post("/api/cards", body: { title: "New" })

    assert_equal({ "id" => "42", "title" => "Created" }, response.body)
  end

  def test_201_with_body_does_not_follow_location
    stub_request(:post, "#{BASE}/api/cards")
      .to_return(status: 201, body: '{"id":"42"}', headers: { "Content-Type" => "application/json", "Location" => "/api/cards/42" })

    response = @client.post("/api/cards", body: { title: "New" })

    assert_equal 201, response.status
    assert_equal({ "id" => "42" }, response.body)
  end

  # --- Error responses ---

  def test_401_raises_auth_error
    stub_request(:get, "#{BASE}/api/boards")
      .to_return(status: 401, body: '{"error":"invalid token"}', headers: { "Content-Type" => "application/json" })

    error = assert_raises(Fizzy::AuthError) { @client.get("/api/boards") }

    assert_equal 401, error.status
    assert_equal({ "error" => "invalid token" }, error.body)
  end

  def test_403_raises_forbidden_error
    stub_request(:get, "#{BASE}/api/boards")
      .to_return(status: 403, body: '{"error":"forbidden"}', headers: { "Content-Type" => "application/json" })

    error = assert_raises(Fizzy::ForbiddenError) { @client.get("/api/boards") }

    assert_equal 403, error.status
  end

  def test_404_raises_not_found_error
    stub_request(:get, "#{BASE}/api/boards/999")
      .to_return(status: 404, body: '{"error":"not found"}', headers: { "Content-Type" => "application/json" })

    error = assert_raises(Fizzy::NotFoundError) { @client.get("/api/boards/999") }

    assert_equal 404, error.status
  end

  def test_422_raises_validation_error_with_parsed_error
    stub_request(:post, "#{BASE}/api/boards")
      .to_return(status: 422, body: '{"error":"Name is required"}', headers: { "Content-Type" => "application/json" })

    error = assert_raises(Fizzy::ValidationError) { @client.post("/api/boards", body: {}) }

    assert_equal 422, error.status
    assert_equal "Name is required", error.message
  end

  def test_422_raises_validation_error_with_errors_string_array
    stub_request(:post, "#{BASE}/api/boards")
      .to_return(status: 422, body: '{"errors":["Name is required","Slug is taken"]}', headers: { "Content-Type" => "application/json" })

    error = assert_raises(Fizzy::ValidationError) { @client.post("/api/boards", body: {}) }

    assert_equal "Validation failed\n  - Name is required\n  - Slug is taken", error.message
  end

  def test_422_raises_validation_error_with_errors_hash_array
    body = '{"errors":[{"field":"title","message":"can\'t be blank"},{"field":"slug","message":"is already taken"}]}'
    stub_request(:post, "#{BASE}/api/boards")
      .to_return(status: 422, body: body, headers: { "Content-Type" => "application/json" })

    error = assert_raises(Fizzy::ValidationError) { @client.post("/api/boards", body: {}) }

    assert_equal "Validation failed\n  - title: can't be blank\n  - slug: is already taken", error.message
  end

  def test_422_raises_validation_error_with_unparseable_body
    stub_request(:post, "#{BASE}/api/boards")
      .to_return(status: 422, body: "Not JSON", headers: { "Content-Type" => "text/plain" })

    error = assert_raises(Fizzy::ValidationError) { @client.post("/api/boards", body: {}) }

    assert_equal "Not JSON", error.message
  end

  def test_429_raises_rate_limit_error
    stub_request(:get, "#{BASE}/api/boards")
      .to_return(status: 429, body: "", headers: { "Content-Type" => "application/json" })

    error = assert_raises(Fizzy::RateLimitError) { @client.get("/api/boards") }

    assert_equal 429, error.status
  end

  def test_500_raises_server_error
    stub_request(:get, "#{BASE}/api/boards")
      .to_return(status: 500, body: "Internal Server Error")

    error = assert_raises(Fizzy::ServerError) { @client.get("/api/boards") }

    assert_equal 500, error.status
  end

  # --- Network errors ---

  def test_timeout_raises_network_error
    stub_request(:get, "#{BASE}/api/boards").to_timeout

    assert_raises(Fizzy::NetworkError) { @client.get("/api/boards") }
  end

  def test_connection_refused_raises_network_error
    stub_request(:get, "#{BASE}/api/boards").to_raise(Errno::ECONNREFUSED)

    assert_raises(Fizzy::NetworkError) { @client.get("/api/boards") }
  end

  # --- Response ---

  def test_response_is_data_define
    response = Fizzy::Response.new(body: { "a" => 1 }, headers: {}, status: 200)

    assert_equal({ "a" => 1 }, response.body)
    assert_equal({}, response.headers)
    assert_equal 200, response.status
  end

  # --- Connection auto-close ---

  def test_connection_registers_at_exit_hook
    stub_request(:get, "#{BASE}/api/boards")
      .to_return(status: 200, body: "[]", headers: { "Content-Type" => "application/json" })

    at_exit_called = false
    @client.stub(:at_exit, ->(&_block) { at_exit_called = true }) do
      @client.get("/api/boards")
    end

    assert at_exit_called, "Expected at_exit to be registered when connection is created"
  end
end
