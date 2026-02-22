# frozen_string_literal: true

require_relative "test_helper"

class AuthTest < Minitest::Test
  include TestConfig

  def setup
    setup_config
    @original_env = ENV.fetch("FIZZY_TOKEN", nil)
    ENV.delete("FIZZY_TOKEN")
  end

  def teardown
    if @original_env
      ENV["FIZZY_TOKEN"] = @original_env
    else
      ENV.delete("FIZZY_TOKEN")
    end
    teardown_config
  end

  # --- ENV var path ---

  def test_resolve_with_env_token_and_account_slug
    ENV["FIZZY_TOKEN"] = "env-token-123"

    result = Fizzy::Auth.resolve("acme")

    assert_equal "env-token-123", result["access_token"]
    assert_equal "acme", result["account_slug"]
  end

  def test_resolve_with_env_token_without_account_slug_raises
    ENV["FIZZY_TOKEN"] = "env-token-123"

    assert_raises(Fizzy::AuthError) { Fizzy::Auth.resolve }
  end

  # --- Token file path ---

  def test_resolve_from_token_file_with_default_account
    token_data = {
      "default_account" => "acme",
      "accounts" => [
        { "account_slug" => "acme", "access_token" => "file-token-1" },
        { "account_slug" => "other", "access_token" => "file-token-2" }
      ]
    }

    File.stub(:exist?, ->(path) { path == Fizzy::Auth::TOKEN_FILE || File.method(:exist?).unbind.bind(File).call(path) }) do
      File.stub(:read, ->(path) { path == Fizzy::Auth::TOKEN_FILE ? token_data.to_json : File.method(:read).unbind.bind(File).call(path) }) do
        result = Fizzy::Auth.resolve

        assert_equal "file-token-1", result["access_token"]
        assert_equal "acme", result["account_slug"]
      end
    end
  end

  def test_resolve_from_token_file_with_explicit_account
    token_data = {
      "default_account" => "acme",
      "accounts" => [
        { "account_slug" => "acme", "access_token" => "file-token-1" },
        { "account_slug" => "other", "access_token" => "file-token-2" }
      ]
    }

    File.stub(:exist?, ->(path) { path == Fizzy::Auth::TOKEN_FILE || File.method(:exist?).unbind.bind(File).call(path) }) do
      File.stub(:read, ->(path) { path == Fizzy::Auth::TOKEN_FILE ? token_data.to_json : File.method(:read).unbind.bind(File).call(path) }) do
        result = Fizzy::Auth.resolve("other")

        assert_equal "file-token-2", result["access_token"]
        assert_equal "other", result["account_slug"]
      end
    end
  end

  def test_resolve_raises_when_token_file_missing
    File.stub(:exist?, ->(path) { path == Fizzy::Auth::TOKEN_FILE ? false : File.method(:exist?).unbind.bind(File).call(path) }) do
      assert_raises(Fizzy::AuthError) { Fizzy::Auth.resolve }
    end
  end

  def test_resolve_raises_when_account_not_found
    token_data = {
      "default_account" => "acme",
      "accounts" => [
        { "account_slug" => "acme", "access_token" => "file-token-1" }
      ]
    }

    File.stub(:exist?, ->(path) { path == Fizzy::Auth::TOKEN_FILE || File.method(:exist?).unbind.bind(File).call(path) }) do
      File.stub(:read, ->(path) { path == Fizzy::Auth::TOKEN_FILE ? token_data.to_json : File.method(:read).unbind.bind(File).call(path) }) do
        assert_raises(Fizzy::AuthError) { Fizzy::Auth.resolve("nonexistent") }
      end
    end
  end

  # --- normalize_slug ---

  def test_normalize_slug_strips_leading_slash
    assert_equal "acme", Fizzy::Auth.normalize_slug("/acme")
  end

  def test_normalize_slug_leaves_clean_slug_unchanged
    assert_equal "acme", Fizzy::Auth.normalize_slug("acme")
  end

  def test_normalize_slug_handles_nil
    assert_nil Fizzy::Auth.normalize_slug(nil)
  end

  # --- resolve normalizes slugs ---

  def test_resolve_with_env_token_normalizes_slug
    ENV["FIZZY_TOKEN"] = "env-token-123"

    result = Fizzy::Auth.resolve("/acme")

    assert_equal "acme", result["account_slug"]
  end

  def test_resolve_from_file_normalizes_slug
    token_data = {
      "default_account" => "/acme",
      "accounts" => [
        { "account_slug" => "/acme", "access_token" => "file-token-1" }
      ]
    }

    File.stub(:exist?, ->(path) { path == Fizzy::Auth::TOKEN_FILE || File.method(:exist?).unbind.bind(File).call(path) }) do
      File.stub(:read, ->(path) { path == Fizzy::Auth::TOKEN_FILE ? token_data.to_json : File.method(:read).unbind.bind(File).call(path) }) do
        result = Fizzy::Auth.resolve

        assert_equal "file-token-1", result["access_token"]
      end
    end
  end
end
