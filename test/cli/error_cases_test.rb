# frozen_string_literal: true

require_relative "../test_helper"

class CLIErrorCasesTest < Minitest::Test
  include TestConfig

  BASE = "https://app.fizzy.do"

  ACCOUNT = {
    "access_token" => "test-token",
    "account_slug" => "test-team",
    "account_name" => "Test Team",
    "user" => { "name" => "Test User", "email_address" => "test@example.com" }
  }.freeze

  def setup
    setup_config
  end

  def teardown
    teardown_config
  end

  def test_404_response_raises_not_found_error
    stub_request(:get, "#{BASE}/test-team/boards/nonexistent")
      .to_return(
        status: 404,
        body: { "error" => "not found" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    Fizzy::Auth.stub(:resolve, ACCOUNT) do
      error = assert_raises(Fizzy::NotFoundError) do
        Fizzy::CLI::Boards.new([], {}, {}).invoke(:get, ["nonexistent"])
      end

      assert_equal 404, error.status
    end
  end

  def test_422_response_shows_formatted_error
    stub_request(:post, "#{BASE}/test-team/boards")
      .to_return(
        status: 422,
        body: { "errors" => ["Name is required", "Slug is taken"] }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    Fizzy::Auth.stub(:resolve, ACCOUNT) do
      error = assert_raises(Fizzy::ValidationError) do
        Fizzy::CLI::Boards.new([], {}, {}).invoke(:create, [""])
      end

      assert_match(/Name is required/, error.message)
      assert_match(/Slug is taken/, error.message)
    end
  end
end
