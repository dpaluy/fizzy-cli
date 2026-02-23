# frozen_string_literal: true

require_relative "../test_helper"
require "tmpdir"

class CLIColumnsTest < Minitest::Test
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

  def test_columns_list_with_board_flag
    stub_request(:get, "#{BASE}/test-team/boards/b1/columns")
      .to_return(
        status: 200,
        body: [{ "id" => "c1", "name" => "To Do", "position" => 0 }].to_json,
        headers: { "Content-Type" => "application/json" }
      )

    out, = capture_io do
      Fizzy::Auth.stub(:resolve, ACCOUNT) do
        Fizzy::CLI::Columns.start(["list", "--board", "b1"])
      end
    end

    assert_match(/c1\s+To Do\s+0/, out)
  end

  def test_columns_list_uses_project_config_board
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, ".fizzy.yml"), YAML.dump("account" => "test-team", "board" => "b1"))

      stub_request(:get, "#{BASE}/test-team/boards/b1/columns")
        .to_return(
          status: 200,
          body: [{ "id" => "c1", "name" => "To Do", "position" => 0 }].to_json,
          headers: { "Content-Type" => "application/json" }
        )

      out, = capture_io do
        Fizzy::Auth.stub(:resolve, ACCOUNT) do
          Fizzy::ProjectConfig.stub(:new, Fizzy::ProjectConfig.new(dir)) do
            Fizzy::CLI::Columns.new([], {}, {}).invoke(:list)
          end
        end
      end

      assert_match(/c1\s+To Do\s+0/, out)
    end
  end

  def test_columns_list_flag_overrides_project_config
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, ".fizzy.yml"), YAML.dump("board" => "config-board"))

      stub_request(:get, "#{BASE}/test-team/boards/flag-board/columns")
        .to_return(
          status: 200,
          body: [{ "id" => "c1", "name" => "To Do", "position" => 0 }].to_json,
          headers: { "Content-Type" => "application/json" }
        )

      out, = capture_io do
        Fizzy::Auth.stub(:resolve, ACCOUNT) do
          Fizzy::ProjectConfig.stub(:new, Fizzy::ProjectConfig.new(dir)) do
            Fizzy::CLI::Columns.start(["list", "--board", "flag-board"])
          end
        end
      end

      assert_match(/c1\s+To Do/, out)
      assert_not_requested(:get, "#{BASE}/test-team/boards/config-board/columns")
    end
  end

  def test_require_board_raises_when_no_board_from_any_source
    Dir.mktmpdir do |dir|
      err = assert_raises(Thor::Error) do
        Fizzy::Auth.stub(:resolve, ACCOUNT) do
          Fizzy::ProjectConfig.stub(:new, Fizzy::ProjectConfig.new(dir)) do
            Fizzy::CLI::Columns.new([], {}, {}).invoke(:list)
          end
        end
      end

      assert_match(/No value provided for option '--board'/, err.message)
      assert_match(/\.fizzy\.yml/, err.message)
    end
  end
end
