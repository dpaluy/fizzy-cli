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

  ACCOUNT_WITH_URL = ACCOUNT.merge("url" => "https://fizzy.mycompany.com").freeze

  def setup
    setup_config
  end

  def teardown
    ENV.delete("FIZZY_URL")
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

  def test_auth_status_uses_custom_url_from_account
    stub_request(:get, "https://fizzy.mycompany.com/my/identity")
      .to_return(
        status: 200,
        body: { "accounts" => [{ "slug" => "test-team", "name" => "Test Team" }] }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    out, = capture_io do
      Fizzy::Auth.stub(:resolve, ACCOUNT_WITH_URL) do
        Fizzy::CLI::AuthCommands.new([], {}, {}).invoke(:status)
      end
    end

    assert_match(%r{URL: https://fizzy\.mycompany\.com}, out)
    assert_match(/Account: Test Team/, out)
  end

  def test_base_url_env_beats_project_config_and_account
    ENV["FIZZY_URL"] = "https://env.example.com"
    cmd = Fizzy::CLI::AuthCommands.new([], {}, {})

    project_config = Minitest::Mock.new
    project_config.expect(:url, "https://project.example.com")
    project_config.expect(:account, nil)

    account_with_url = ACCOUNT.merge("url" => "https://account.example.com")

    url = cmd.stub(:project_config, project_config) do
      Fizzy::Auth.stub(:resolve, account_with_url) do
        cmd.send(:base_url)
      end
    end

    assert_equal "https://env.example.com", url
  end

  def test_base_url_project_config_beats_account
    cmd = Fizzy::CLI::AuthCommands.new([], {}, {})

    project_config = Minitest::Mock.new
    project_config.expect(:url, "https://project.example.com")
    project_config.expect(:account, nil)

    account_with_url = ACCOUNT.merge("url" => "https://account.example.com")

    url = cmd.stub(:project_config, project_config) do
      Fizzy::Auth.stub(:resolve, account_with_url) do
        cmd.send(:base_url)
      end
    end

    assert_equal "https://project.example.com", url
  end

  def test_base_url_falls_back_to_default
    cmd = Fizzy::CLI::AuthCommands.new([], {}, {})

    project_config = Minitest::Mock.new
    project_config.expect(:url, nil)
    project_config.expect(:account, nil)

    url = cmd.stub(:project_config, project_config) do
      Fizzy::Auth.stub(:resolve, ACCOUNT) do
        cmd.send(:base_url)
      end
    end

    assert_equal Fizzy::Client::DEFAULT_BASE_URL, url
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
