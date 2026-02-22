# frozen_string_literal: true

require_relative "test_helper"

class ErrorsTest < Minitest::Test
  include TestConfig

  def setup
    setup_config
  end

  def teardown
    teardown_config
  end

  def test_error_inherits_from_standard_error
    assert Fizzy::Error < StandardError
  end

  def test_error_stores_status_and_body
    error = Fizzy::Error.new("something broke", status: 500, body: { "error" => "bad" })
    assert_equal "something broke", error.message
    assert_equal 500, error.status
    assert_equal({ "error" => "bad" }, error.body)
  end

  def test_error_defaults_to_nil_status_and_body
    error = Fizzy::Error.new("oops")
    assert_nil error.status
    assert_nil error.body
  end

  def test_auth_error_inherits_from_error
    assert Fizzy::AuthError < Fizzy::Error
  end

  def test_not_found_error_inherits_from_error
    assert Fizzy::NotFoundError < Fizzy::Error
  end

  def test_validation_error_inherits_from_error
    assert Fizzy::ValidationError < Fizzy::Error
  end

  def test_forbidden_error_inherits_from_error
    assert Fizzy::ForbiddenError < Fizzy::Error
  end

  def test_server_error_inherits_from_error
    assert Fizzy::ServerError < Fizzy::Error
  end

  def test_rate_limit_error_inherits_from_error
    assert Fizzy::RateLimitError < Fizzy::Error
  end

  def test_network_error_inherits_from_error
    assert Fizzy::NetworkError < Fizzy::Error
  end

  def test_subclasses_store_status_and_body
    error = Fizzy::AuthError.new("unauthorized", status: 401, body: { "error" => "bad token" })
    assert_equal 401, error.status
    assert_equal({ "error" => "bad token" }, error.body)
  end
end
