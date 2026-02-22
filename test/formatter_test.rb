# frozen_string_literal: true

require_relative "test_helper"
require "stringio"

class FormatterTest < Minitest::Test
  include TestConfig

  def setup
    setup_config
    @io = StringIO.new
  end

  def teardown
    teardown_config
  end

  # --- table ---

  def test_table_outputs_headers_and_rows
    Fizzy::Formatter.table(
      [["1", "Board A"], ["2", "Board B"]],
      headers: %w[ID Name],
      io: @io
    )

    lines = @io.string.split("\n")
    assert_equal 4, lines.length
    assert_match(/ID\s+Name/, lines[0])
    assert_match(/^-+\s+-+$/, lines[1])
    assert_match(/1\s+Board A/, lines[2])
    assert_match(/2\s+Board B/, lines[3])
  end

  def test_table_with_empty_rows_outputs_nothing
    Fizzy::Formatter.table([], headers: %w[ID Name], io: @io)

    assert_empty @io.string
  end

  def test_table_pads_columns_to_max_width
    Fizzy::Formatter.table(
      [["1", "Short"], ["2", "A Much Longer Name"]],
      headers: %w[ID Name],
      io: @io
    )

    lines = @io.string.split("\n")
    assert lines[1].include?("-" * "A Much Longer Name".length)
  end

  # --- json ---

  def test_json_outputs_pretty_json
    Fizzy::Formatter.json({ "id" => "1", "name" => "Board" }, io: @io)

    parsed = JSON.parse(@io.string)
    assert_equal({ "id" => "1", "name" => "Board" }, parsed)
    assert @io.string.include?("\n")
  end

  def test_json_outputs_array
    Fizzy::Formatter.json([{ "id" => "1" }, { "id" => "2" }], io: @io)

    parsed = JSON.parse(@io.string)
    assert_equal [{ "id" => "1" }, { "id" => "2" }], parsed
  end

  # --- detail ---

  def test_detail_outputs_key_value_pairs
    Fizzy::Formatter.detail([["ID", "1"], ["Name", "Board A"], ["Status", "active"]], io: @io)

    lines = @io.string.split("\n")
    assert_equal 3, lines.length
    assert_match(/ID\s+1/, lines[0])
    assert_match(/Name\s+Board A/, lines[1])
    assert_match(/Status\s+active/, lines[2])
  end

  def test_detail_right_aligns_keys
    Fizzy::Formatter.detail([%w[ID 1], %w[Name Board]], io: @io)

    lines = @io.string.split("\n")
    assert_match(/^\s+ID\s+1$/, lines[0])
    assert_match(/^Name\s+Board$/, lines[1])
  end

  def test_table_with_nil_values
    Fizzy::Formatter.table(
      [["1", nil], [nil, "Board B"]],
      headers: %w[ID Name],
      io: @io
    )

    lines = @io.string.split("\n")
    assert_equal 4, lines.length
    assert_match(/1\s+$/, lines[2])
    assert_match(/Board B/, lines[3])
  end

  def test_table_with_cjk_characters
    Fizzy::Formatter.table(
      [%w[1 こんにちは], %w[2 Hello]],
      headers: %w[ID Name],
      io: @io
    )

    lines = @io.string.split("\n")
    # "こんにちは" is 5 chars but 10 display columns
    # "Hello" is 5 chars and 5 display columns
    # Column width should be 10 (max display width)
    # The separator line should have 10 dashes for the Name column
    assert_equal 10, lines[1].split("  ").last.length
  end

  def test_table_with_emoji
    Fizzy::Formatter.table(
      [["1", "🎉 Party"], ["2", "Normal"]],
      headers: %w[ID Name],
      io: @io
    )

    lines = @io.string.split("\n")
    # Both rows should have consistent alignment
    assert_equal 4, lines.length
  end

  # --- display_width ---

  def test_display_width_ascii
    assert_equal 5, Fizzy::Formatter.send(:display_width, "hello")
  end

  def test_display_width_cjk
    assert_equal 10, Fizzy::Formatter.send(:display_width, "こんにちは")
  end

  def test_display_width_mixed
    assert_equal 9, Fizzy::Formatter.send(:display_width, "hi こんに")
  end

  def test_display_width_emoji
    assert_equal 2, Fizzy::Formatter.send(:display_width, "🎉")
  end

  def test_display_width_nil
    assert_equal 0, Fizzy::Formatter.send(:display_width, nil)
  end

  def test_display_width_empty
    assert_equal 0, Fizzy::Formatter.send(:display_width, "")
  end

  # --- truncate ---

  def test_truncate_short_string_unchanged
    assert_equal "hello", Fizzy::Formatter.truncate("hello", 10)
  end

  def test_truncate_exact_length_unchanged
    assert_equal "hello", Fizzy::Formatter.truncate("hello", 5)
  end

  def test_truncate_long_string_adds_ellipsis
    result = Fizzy::Formatter.truncate("hello world", 5)
    assert_equal 5, result.length
    assert_equal "hell\u2026", result
  end

  def test_truncate_nil_returns_empty_string
    assert_equal "", Fizzy::Formatter.truncate(nil, 10)
  end

  def test_truncate_empty_string_returns_empty
    assert_equal "", Fizzy::Formatter.truncate("", 10)
  end
end
