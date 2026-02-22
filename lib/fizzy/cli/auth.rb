# frozen_string_literal: true

require "fileutils"

module Fizzy
  class CLI < Thor
    class AuthCommands < Thor
      include Base

      namespace "auth"

      desc "identity", "Show current identity"
      def identity
        resp = client.get("/my/identity")
        if json?
          Formatter.json(resp.body)
        else
          resp.body["accounts"].each do |a|
            puts "#{a["name"]} (#{a["slug"]})"
            puts "  #{a["user"]["name"]} <#{a["user"]["email_address"]}> — #{a["user"]["role"]}"
          end
        end
      end

      desc "login", "Authenticate with a Personal Access Token"
      option :token, required: true, desc: "Personal Access Token"
      def login
        token = options[:token]

        # Verify token by fetching identity
        c = Client.new(token: token, account_slug: "")
        resp = c.get("/my/identity")
        accounts = resp.body["accounts"]

        raise AuthError, "No accounts found for this token" if accounts.empty?

        # Build tokens data
        token_accounts = accounts.map do |a|
          {
            "account_slug" => Auth.normalize_slug(a["slug"]),
            "account_name" => a["name"],
            "account_id" => a["id"],
            "access_token" => token,
            "user" => {
              "id" => a["user"]["id"],
              "name" => a["user"]["name"],
              "email_address" => a["user"]["email_address"],
              "role" => a["user"]["role"]
            },
            "created_at" => Time.now.utc.strftime("%Y-%m-%dT%H:%M:%S.%3NZ")
          }
        end

        data = {
          "accounts" => token_accounts,
          "default_account" => Auth.normalize_slug(accounts.first["slug"])
        }

        FileUtils.mkdir_p(Auth::CONFIG_DIR)
        File.write(Auth::TOKEN_FILE, YAML.dump(data))
        File.chmod(0o600, Auth::TOKEN_FILE)

        puts "Authenticated as #{token_accounts.first.dig("user", "name")}"
        token_accounts.each do |a|
          marker = a["account_slug"] == data["default_account"] ? " (default)" : ""
          puts "  #{a["account_name"]} (#{a["account_slug"]})#{marker}"
        end
      end

      desc "status", "Show current auth status"
      def status
        acct = Auth.resolve
        c = Client.new(token: acct["access_token"], account_slug: acct["account_slug"])
        resp = c.get("/my/identity")

        puts "Token: #{Auth::TOKEN_FILE}"
        puts "Account: #{acct["account_name"]} (#{acct["account_slug"]})"
        puts "User: #{acct.dig("user", "name")} <#{acct.dig("user", "email_address")}>"

        accounts_count = resp.body["accounts"].size
        puts "Accounts: #{accounts_count}" if accounts_count > 1
      rescue Fizzy::AuthError => e
        puts "Not authenticated: #{e.message}"
      end

      desc "accounts", "List available accounts"
      def accounts
        data = YAML.safe_load_file(Auth::TOKEN_FILE, permitted_classes: [Time])
        data["accounts"].each do |a|
          marker = a["account_slug"] == data["default_account"] ? " *" : ""
          puts "#{a["account_name"]} (#{a["account_slug"]})#{marker}"
          puts "  #{a.dig("user", "name")} <#{a.dig("user", "email_address")}>"
        end
      end

      desc "switch ACCOUNT_SLUG", "Set default account"
      def switch(account_slug)
        data = YAML.safe_load_file(Auth::TOKEN_FILE, permitted_classes: [Time])
        normalized = Auth.normalize_slug(account_slug)
        account = data["accounts"].find { |a| Auth.normalize_slug(a["account_slug"]) == normalized }
        raise AuthError, "No account found for #{account_slug}" unless account

        data["default_account"] = normalized
        File.write(Auth::TOKEN_FILE, YAML.dump(data))

        puts "Switched to #{account["account_name"]} (#{normalized})"
      end
    end
  end
end
