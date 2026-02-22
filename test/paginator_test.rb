# frozen_string_literal: true

require_relative "test_helper"

class PaginatorTest < Minitest::Test
  include TestConfig

  BASE = "https://app.fizzy.do"

  def setup
    setup_config
    @client = Fizzy::Client.new(token: "test-token", account_slug: "acme")
    @paginator = Fizzy::Paginator.new(@client)
  end

  def teardown
    teardown_config
  end

  def test_single_page_no_link_header
    stub_request(:get, "#{BASE}/api/cards")
      .to_return(
        status: 200,
        body: '[{"id":"1"},{"id":"2"}]',
        headers: { "Content-Type" => "application/json" }
      )

    items = @paginator.all("/api/cards")

    assert_equal [{ "id" => "1" }, { "id" => "2" }], items
  end

  def test_multi_page_follows_link_header
    stub_request(:get, "#{BASE}/api/cards")
      .to_return(
        status: 200,
        body: '[{"id":"1"}]',
        headers: {
          "Content-Type" => "application/json",
          "Link" => '<https://app.fizzy.do/api/cards?page=2>; rel="next"'
        }
      )

    stub_request(:get, "#{BASE}/api/cards?page=2")
      .to_return(
        status: 200,
        body: '[{"id":"2"}]',
        headers: { "Content-Type" => "application/json" }
      )

    items = @paginator.all("/api/cards")

    assert_equal [{ "id" => "1" }, { "id" => "2" }], items
  end

  def test_three_pages
    stub_request(:get, "#{BASE}/api/cards")
      .to_return(
        status: 200,
        body: '[{"id":"1"}]',
        headers: {
          "Content-Type" => "application/json",
          "Link" => '<https://app.fizzy.do/api/cards?page=2>; rel="next"'
        }
      )

    stub_request(:get, "#{BASE}/api/cards?page=2")
      .to_return(
        status: 200,
        body: '[{"id":"2"}]',
        headers: {
          "Content-Type" => "application/json",
          "Link" => '<https://app.fizzy.do/api/cards?page=3>; rel="next"'
        }
      )

    stub_request(:get, "#{BASE}/api/cards?page=3")
      .to_return(
        status: 200,
        body: '[{"id":"3"}]',
        headers: { "Content-Type" => "application/json" }
      )

    items = @paginator.all("/api/cards")

    assert_equal [{ "id" => "1" }, { "id" => "2" }, { "id" => "3" }], items
  end

  def test_each_page_yields_each_page_body
    stub_request(:get, "#{BASE}/api/cards")
      .to_return(
        status: 200,
        body: '[{"id":"1"}]',
        headers: {
          "Content-Type" => "application/json",
          "Link" => '<https://app.fizzy.do/api/cards?page=2>; rel="next"'
        }
      )

    stub_request(:get, "#{BASE}/api/cards?page=2")
      .to_return(
        status: 200,
        body: '[{"id":"2"}]',
        headers: { "Content-Type" => "application/json" }
      )

    pages = []
    @paginator.each_page("/api/cards") { |page| pages << page }

    assert_equal 2, pages.length
    assert_equal [{ "id" => "1" }], pages[0]
    assert_equal [{ "id" => "2" }], pages[1]
  end

  def test_passes_params_on_first_request_only
    stub_request(:get, "#{BASE}/api/cards?status=open")
      .to_return(
        status: 200,
        body: '[{"id":"1"}]',
        headers: {
          "Content-Type" => "application/json",
          "Link" => '<https://app.fizzy.do/api/cards?page=2&status=open>; rel="next"'
        }
      )

    stub_request(:get, "#{BASE}/api/cards?page=2&status=open")
      .to_return(
        status: 200,
        body: '[{"id":"2"}]',
        headers: { "Content-Type" => "application/json" }
      )

    items = @paginator.all("/api/cards", params: { status: "open" })

    assert_equal [{ "id" => "1" }, { "id" => "2" }], items
  end
end
