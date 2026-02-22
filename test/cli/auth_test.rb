# frozen_string_literal: true

require_relative "../test_helper"

class CLIAuthTest < Minitest::Test
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

  def test_auth_status_shows_account_info
    stub_request(:get, "#{BASE}/my/identity")
      .to_return(
        status: 200,
        body: { "accounts" => [{ "slug" => "test-team", "name" => "Test Team" }] }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    out, = capture_io do
      Fizzy::Auth.stub(:resolve, ACCOUNT) do
        Fizzy::CLI::AuthCommands.new([], {}, {}).invoke(:status)
      end
    end

    assert_match(/Account: Test Team \(test-team\)/, out)
    assert_match(/User: Test User <test@example.com>/, out)
  end

  def test_auth_identity_shows_accounts
    identity = {
      "accounts" => [
        { "slug" => "acme", "name" => "Acme Corp",
          "user" => { "name" => "Alice", "email_address" => "alice@acme.com", "role" => "admin" } },
        { "slug" => "other", "name" => "Other Inc",
          "user" => { "name" => "Alice", "email_address" => "alice@other.com", "role" => "member" } }
      ]
    }

    stub_request(:get, "#{BASE}/my/identity")
      .to_return(
        status: 200,
        body: identity.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    out, = capture_io do
      Fizzy::Auth.stub(:resolve, ACCOUNT) do
        Fizzy::CLI::AuthCommands.new([], {}, {}).invoke(:identity)
      end
    end

    assert_match(/Acme Corp \(acme\)/, out)
    assert_match(/Alice <alice@acme.com>/, out)
    assert_match(/Other Inc \(other\)/, out)
  end
end
