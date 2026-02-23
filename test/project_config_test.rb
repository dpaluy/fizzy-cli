# frozen_string_literal: true

require_relative "test_helper"
require "tmpdir"

class ProjectConfigTest < Minitest::Test
  def test_finds_config_in_current_dir
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, ".fizzy.yml"), YAML.dump("account" => "acme", "board" => "b1"))

      config = Fizzy::ProjectConfig.new(dir)

      assert config.found?
      assert_equal "acme", config.account
      assert_equal "b1", config.board
      assert_equal File.join(dir, ".fizzy.yml"), config.path
    end
  end

  def test_walks_up_parent_directories
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, ".fizzy.yml"), YAML.dump("account" => "acme", "board" => "b1"))
      child = File.join(dir, "sub", "deep")
      FileUtils.mkdir_p(child)

      config = Fizzy::ProjectConfig.new(child)

      assert config.found?
      assert_equal "acme", config.account
      assert_equal File.join(dir, ".fizzy.yml"), config.path
    end
  end

  def test_returns_nil_when_no_config
    Dir.mktmpdir do |dir|
      config = Fizzy::ProjectConfig.new(dir)

      refute config.found?
      assert_nil config.account
      assert_nil config.board
      assert_nil config.path
    end
  end

  def test_raises_on_bad_yaml
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, ".fizzy.yml"), "{ bad yaml: [")

      err = assert_raises(Thor::Error) do
        Fizzy::ProjectConfig.new(dir)
      end

      assert_match(/Bad \.fizzy\.yml/, err.message)
    end
  end

  def test_handles_blank_file
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, ".fizzy.yml"), "")

      config = Fizzy::ProjectConfig.new(dir)

      assert config.found?
      assert_nil config.account
      assert_nil config.board
    end
  end

  def test_handles_account_only
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, ".fizzy.yml"), YAML.dump("account" => "acme"))

      config = Fizzy::ProjectConfig.new(dir)

      assert config.found?
      assert_equal "acme", config.account
      assert_nil config.board
    end
  end

  def test_boards_returns_cached_hash
    Dir.mktmpdir do |dir|
      data = { "account" => "acme", "boards" => { "b1" => "Sprint Board", "b2" => "Backlog" } }
      File.write(File.join(dir, ".fizzy.yml"), YAML.dump(data))

      config = Fizzy::ProjectConfig.new(dir)

      assert_equal({ "b1" => "Sprint Board", "b2" => "Backlog" }, config.boards)
    end
  end

  def test_boards_returns_empty_hash_when_missing
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, ".fizzy.yml"), YAML.dump("account" => "acme"))

      config = Fizzy::ProjectConfig.new(dir)

      assert_equal({}, config.boards)
    end
  end

  def test_url_returns_custom_url
    Dir.mktmpdir do |dir|
      data = { "account" => "acme", "url" => "https://fizzy.mycompany.com" }
      File.write(File.join(dir, ".fizzy.yml"), YAML.dump(data))

      config = Fizzy::ProjectConfig.new(dir)

      assert_equal "https://fizzy.mycompany.com", config.url
    end
  end

  def test_url_returns_nil_when_missing
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, ".fizzy.yml"), YAML.dump("account" => "acme"))

      config = Fizzy::ProjectConfig.new(dir)

      assert_nil config.url
    end
  end
end
