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

module Fizzy
  class CLI < Thor
    class_option :json, type: :boolean, desc: "Output as JSON"
    class_option :account, type: :string, desc: "Account slug override"

    desc "version", "Print version"
    def version
      puts "fizzy-cli #{VERSION}"
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

    def self.exit_on_failure? = true
  end
end
