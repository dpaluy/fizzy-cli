# frozen_string_literal: true

require_relative "../test_helper"

class CLIBoardsTest < Minitest::Test
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

  def test_boards_list_outputs_table
    stub_request(:get, "#{BASE}/test-team/boards")
      .to_return(
        status: 200,
        body: [
          { "id" => "b1", "name" => "Sprint Board", "open_cards_count" => 5, "columns_count" => 3 },
          { "id" => "b2", "name" => "Backlog", "open_cards_count" => 12, "columns_count" => 4 }
        ].to_json,
        headers: { "Content-Type" => "application/json" }
      )

    out, = capture_io do
      Fizzy::Auth.stub(:resolve, ACCOUNT) do
        Fizzy::CLI::Boards.new([], {}, {}).invoke(:list)
      end
    end

    assert_match(/ID\s+Name\s+Cards\s+Columns/, out)
    assert_match(/b1\s+Sprint Board\s+5\s+3/, out)
    assert_match(/b2\s+Backlog\s+12\s+4/, out)
  end

  def test_boards_list_json
    boards = [{ "id" => "b1", "name" => "Sprint Board" }]

    stub_request(:get, "#{BASE}/test-team/boards")
      .to_return(
        status: 200,
        body: boards.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    out, = capture_io do
      Fizzy::Auth.stub(:resolve, ACCOUNT) do
        Fizzy::CLI::Boards.new([], { "json" => true }, {}).invoke(:list)
      end
    end

    parsed = JSON.parse(out)
    assert_equal boards, parsed
  end

  def test_boards_get_outputs_detail
    board = {
      "id" => "b1", "name" => "Sprint Board",
      "open_cards_count" => 5, "columns_count" => 3, "created_at" => "2024-01-15"
    }

    stub_request(:get, "#{BASE}/test-team/boards/b1")
      .to_return(
        status: 200,
        body: board.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    out, = capture_io do
      Fizzy::Auth.stub(:resolve, ACCOUNT) do
        Fizzy::CLI::Boards.new([], {}, {}).invoke(:get, ["b1"])
      end
    end

    assert_match(/ID\s+b1/, out)
    assert_match(/Name\s+Sprint Board/, out)
    assert_match(/Open cards\s+5/, out)
    assert_match(/Columns\s+3/, out)
    assert_match(/Created\s+2024-01-15/, out)
  end

  def test_boards_sync_writes_boards_to_config
    Dir.mktmpdir do |dir|
      config_path = File.join(dir, ".fizzy.yml")
      File.write(config_path, YAML.dump("account" => "test-team", "board" => "b1"))

      stub_request(:get, "#{BASE}/test-team/boards")
        .to_return(
          status: 200,
          body: [
            { "id" => "b1", "name" => "Sprint Board", "open_cards_count" => 5, "columns_count" => 3 },
            { "id" => "b2", "name" => "Backlog", "open_cards_count" => 12, "columns_count" => 4 }
          ].to_json,
          headers: { "Content-Type" => "application/json" }
        )

      out, = capture_io do
        Dir.stub(:pwd, dir) do
          Fizzy::Auth.stub(:resolve, ACCOUNT) do
            Fizzy::CLI::Boards.new([], {}, {}).invoke(:sync)
          end
        end
      end

      assert_match(/Synced 2 board/, out)

      written = YAML.safe_load_file(config_path)
      assert_equal({ "b1" => "Sprint Board", "b2" => "Backlog" }, written["boards"])
      assert_equal "test-team", written["account"]
      assert_equal "b1", written["board"]
    end
  end

  def test_boards_sync_errors_without_config
    Dir.mktmpdir do |dir|
      err = assert_raises(Thor::Error) do
        Dir.stub(:pwd, dir) do
          Fizzy::Auth.stub(:resolve, ACCOUNT) do
            Fizzy::CLI::Boards.new([], {}, {}).invoke(:sync)
          end
        end
      end

      assert_match(/No \.fizzy\.yml found/, err.message)
    end
  end
end
