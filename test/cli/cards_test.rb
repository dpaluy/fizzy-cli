# frozen_string_literal: true

require_relative "../test_helper"

class CLICardsTest < Minitest::Test
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

  def test_cards_list_outputs_table
    cards = [
      { "number" => 1, "title" => "Fix login bug", "board" => { "name" => "Sprint" },
        "status" => "open", "column" => { "name" => "In Progress" } },
      { "number" => 2, "title" => "Add dark mode", "board" => { "name" => "Backlog" },
        "status" => "open", "column" => { "name" => "Todo" } }
    ]

    stub_request(:get, "#{BASE}/test-team/cards?status=open")
      .to_return(
        status: 200,
        body: cards.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    out, = capture_io do
      Fizzy::Auth.stub(:resolve, ACCOUNT) do
        Fizzy::CLI::Cards.new([], {}, {}).invoke(:list)
      end
    end

    assert_match(/#\s+Title\s+Board\s+Status\s+Column/, out)
    assert_match(/1\s+Fix login bug\s+Sprint\s+open\s+In Progress/, out)
    assert_match(/2\s+Add dark mode\s+Backlog\s+open\s+Todo/, out)
  end

  def test_cards_get_outputs_detail
    card = {
      "number" => 42, "title" => "Fix login bug",
      "board" => { "name" => "Sprint" }, "column" => { "name" => "In Progress" },
      "status" => "open", "creator" => { "name" => "Alice" },
      "assignees" => [{ "name" => "Bob" }],
      "tags" => [{ "title" => "bug" }],
      "steps" => [{ "completed" => true }, { "completed" => false }],
      "created_at" => "2024-02-01", "url" => "https://app.fizzy.do/cards/42"
    }

    stub_request(:get, "#{BASE}/test-team/cards/42")
      .to_return(
        status: 200,
        body: card.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    out, = capture_io do
      Fizzy::Auth.stub(:resolve, ACCOUNT) do
        Fizzy::CLI::Cards.new([], {}, {}).invoke(:get, ["42"])
      end
    end

    assert_match(/Number\s+#42/, out)
    assert_match(/Title\s+Fix login bug/, out)
    assert_match(/Board\s+Sprint/, out)
    assert_match(/Status\s+open/, out)
    assert_match(/Assignees\s+Bob/, out)
    assert_match(/Tags\s+bug/, out)
    assert_match(%r{Steps\s+1/2}, out)
  end

  def test_cards_create_posts_correct_body
    stub_request(:post, "#{BASE}/test-team/boards/b1/cards")
      .with { |req| JSON.parse(req.body) == { "title" => "New card" } }
      .to_return(
        status: 200,
        body: { "number" => 99, "title" => "New card", "url" => "https://app.fizzy.do/cards/99" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    out, = capture_io do
      Fizzy::Auth.stub(:resolve, ACCOUNT) do
        Fizzy::CLI::Cards.start(["create", "New card", "--board", "b1"])
      end
    end

    assert_match(/Number\s+#99/, out)
    assert_match(/Title\s+New card/, out)
  end

  def test_cards_create_sends_description_not_body
    stub_request(:post, "#{BASE}/test-team/boards/b1/cards")
      .with { |req| JSON.parse(req.body) == { "title" => "New card", "description" => "<p>Hello</p>" } }
      .to_return(
        status: 200,
        body: { "number" => 99, "title" => "New card", "url" => "https://app.fizzy.do/cards/99" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    out, = capture_io do
      Fizzy::Auth.stub(:resolve, ACCOUNT) do
        Fizzy::CLI::Cards.start(["create", "New card", "--board", "b1", "--body", "<p>Hello</p>"])
      end
    end

    assert_match(/Number\s+#99/, out)
  end

  def test_cards_create_with_column_triages_after_creation
    stub_request(:post, "#{BASE}/test-team/boards/b1/cards")
      .to_return(
        status: 200,
        body: { "number" => 99, "title" => "New card", "url" => "https://app.fizzy.do/cards/99" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    triage_stub = stub_request(:post, "#{BASE}/test-team/cards/99/triage")
                  .with { |req| JSON.parse(req.body) == { "column_id" => "col1" } }
                  .to_return(status: 200, body: "", headers: {})

    capture_io do
      Fizzy::Auth.stub(:resolve, ACCOUNT) do
        Fizzy::CLI::Cards.start(["create", "New card", "--board", "b1", "--column", "col1"])
      end
    end

    assert_requested triage_stub
  end

  def test_cards_update_sends_description_not_body
    stub_request(:put, "#{BASE}/test-team/cards/37")
      .with { |req| JSON.parse(req.body) == { "description" => "<p>Updated</p>" } }
      .to_return(
        status: 200,
        body: { "number" => 37, "title" => "My card" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    out, = capture_io do
      Fizzy::Auth.stub(:resolve, ACCOUNT) do
        Fizzy::CLI::Cards.new([], { "body" => "<p>Updated</p>" }, {}).invoke(:update, ["37"])
      end
    end

    assert_match(/Number\s+#37/, out)
  end

  def test_cards_update_sends_title
    stub_request(:put, "#{BASE}/test-team/cards/37")
      .with { |req| JSON.parse(req.body) == { "title" => "New title" } }
      .to_return(
        status: 200,
        body: { "number" => 37, "title" => "New title" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    out, = capture_io do
      Fizzy::Auth.stub(:resolve, ACCOUNT) do
        Fizzy::CLI::Cards.new([], { "title" => "New title" }, {}).invoke(:update, ["37"])
      end
    end

    assert_match(/Title\s+New title/, out)
  end

  def test_cards_update_raises_when_no_options
    err = assert_raises(Thor::Error) do
      Fizzy::Auth.stub(:resolve, ACCOUNT) do
        Fizzy::CLI::Cards.new([], {}, {}).invoke(:update, ["37"])
      end
    end

    assert_equal "Nothing to update. Provide --title or --body", err.message
  end
end
