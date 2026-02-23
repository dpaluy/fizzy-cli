# frozen_string_literal: true

require_relative "../test_helper"
require "tmpdir"

class CLIInitTest < Minitest::Test
  include TestConfig

  BASE = "https://app.fizzy.do"

  TOKEN_DATA = {
    "accounts" => [
      {
        "account_slug" => "acme",
        "account_name" => "Acme Corp",
        "access_token" => "test-token",
        "user" => { "name" => "Alice", "email_address" => "alice@example.com" }
      }
    ],
    "default_account" => "acme"
  }.freeze

  def setup
    setup_config
  end

  def teardown
    teardown_config
  end

  def test_init_creates_config_with_account_and_board
    Dir.mktmpdir do |dir|
      boards = [
        { "id" => "b1", "name" => "Sprint Board" },
        { "id" => "b2", "name" => "Backlog" }
      ]

      stub_request(:get, "#{BASE}/acme/boards")
        .to_return(status: 200, body: boards.to_json, headers: { "Content-Type" => "application/json" })

      config_path = File.join(dir, ".fizzy.yml")
      out = run_init(dir, "1\ny\n1\n")

      assert File.exist?(config_path), "Expected .fizzy.yml to be created"
      config = YAML.safe_load_file(config_path)
      assert_equal "acme", config["account"]
      assert_equal "b1", config["board"]
      assert_equal({ "b1" => "Sprint Board", "b2" => "Backlog" }, config["boards"])
      assert_match(/Wrote/, out)
    end
  end

  def test_init_creates_config_without_board
    Dir.mktmpdir do |dir|
      boards = [
        { "id" => "b1", "name" => "Sprint Board" },
        { "id" => "b2", "name" => "Backlog" }
      ]

      stub_request(:get, "#{BASE}/acme/boards")
        .to_return(status: 200, body: boards.to_json, headers: { "Content-Type" => "application/json" })

      config_path = File.join(dir, ".fizzy.yml")
      out = run_init(dir, "1\nn\n")

      assert File.exist?(config_path)
      config = YAML.safe_load_file(config_path)
      assert_equal "acme", config["account"]
      assert_nil config["board"]
      assert_equal({ "b1" => "Sprint Board", "b2" => "Backlog" }, config["boards"])
      assert_match(/Wrote/, out)
    end
  end

  private

  def run_init(dir, input)
    out = nil
    Dir.stub(:pwd, dir) do
      Fizzy::Auth.stub(:token_data, TOKEN_DATA) do
        $stdin = StringIO.new(input)
        out, = capture_io { Fizzy::CLI.start(["init"]) }
      end
    end
    out
  ensure
    $stdin = STDIN
  end
end
