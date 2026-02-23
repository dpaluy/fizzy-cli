# frozen_string_literal: true

require "thor"
require_relative "cli/base"
require_relative "cli/boards"
require_relative "cli/cards"
require_relative "cli/columns"
require_relative "cli/steps"
require_relative "cli/comments"
require_relative "cli/reactions"
require_relative "cli/tags"
require_relative "cli/users"
require_relative "cli/notifications"
require_relative "cli/pins"
require_relative "cli/auth"
require_relative "cli/skill"

module Fizzy
  class CLI < Thor
    class_option :json, type: :boolean, desc: "Output as JSON"
    class_option :account, type: :string, desc: "Account slug override"

    desc "version", "Print version"
    def version
      puts "fizzy-cli #{VERSION}"
    end

    desc "init", "Create .fizzy.yml in current directory"
    def init
      config_path = File.join(Dir.pwd, ProjectConfig::FILENAME)
      return if File.exist?(config_path) && !yes?("#{config_path} already exists. Overwrite?")

      selected = pick_account
      config = { "account" => selected["account_slug"] }

      boards = fetch_boards(selected)
      config["boards"] = boards.to_h { |b| [b["id"], b["name"]] } if boards.any?
      config["board"] = pick_board(boards) if boards.any? && yes?("Set a default board?")

      File.write(config_path, YAML.dump(config))
      say "Wrote #{config_path}"
    end

    desc "boards SUBCOMMAND ...ARGS", "Manage boards"
    subcommand "boards", CLI::Boards

    desc "cards SUBCOMMAND ...ARGS", "Manage cards"
    subcommand "cards", CLI::Cards

    desc "columns SUBCOMMAND ...ARGS", "Manage columns"
    subcommand "columns", CLI::Columns

    desc "steps SUBCOMMAND ...ARGS", "Manage card steps"
    subcommand "steps", CLI::Steps

    desc "comments SUBCOMMAND ...ARGS", "Manage card comments"
    subcommand "comments", CLI::Comments

    desc "reactions SUBCOMMAND ...ARGS", "Manage reactions"
    subcommand "reactions", CLI::Reactions

    desc "tags SUBCOMMAND ...ARGS", "List tags"
    subcommand "tags", CLI::Tags

    desc "users SUBCOMMAND ...ARGS", "Manage users"
    subcommand "users", CLI::Users

    desc "notifications SUBCOMMAND ...ARGS", "Manage notifications"
    subcommand "notifications", CLI::Notifications

    desc "pins SUBCOMMAND ...ARGS", "Manage pinned cards"
    subcommand "pins", CLI::Pins

    desc "auth SUBCOMMAND ...ARGS", "Authentication commands"
    subcommand "auth", CLI::AuthCommands

    desc "skill SUBCOMMAND ...ARGS", "Manage AI skill files"
    subcommand "skill", CLI::Skill

    def self.exit_on_failure? = true

    private

    def pick_account
      data = Auth.token_data
      accounts = Array(data["accounts"])
      raise AuthError, "No accounts found. Run: fizzy auth login --token TOKEN" if accounts.empty?

      say "Available accounts:"
      accounts.each_with_index do |a, i|
        marker = a["account_slug"] == data["default_account"] ? " (default)" : ""
        say "  #{i + 1}. #{a["account_name"]} (#{a["account_slug"]})#{marker}"
      end

      choice = ask("Select account number [1]:").strip
      choice = "1" if choice.empty?
      idx = choice.to_i - 1
      raise Thor::Error, "Invalid selection" unless idx >= 0 && idx < accounts.size

      accounts[idx]
    end

    def fetch_boards(account)
      c = Client.new(token: account["access_token"], account_slug: account["account_slug"])
      boards = c.get("boards").body
      say "No boards found." if boards.empty?
      boards
    end

    def pick_board(boards)
      say "Boards:"
      boards.each_with_index do |b, i|
        say "  #{i + 1}. #{b["name"]} (#{b["id"]})"
      end

      board_idx = ask("Select board number:").strip.to_i - 1
      return boards[board_idx]["id"] if board_idx >= 0 && board_idx < boards.size

      say "Invalid selection, skipping board."
      nil
    end
  end
end
