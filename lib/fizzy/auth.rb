# frozen_string_literal: true

module Fizzy
  class Auth
    CONFIG_DIR = File.expand_path("~/.config/fizzy-cli")
    TOKEN_FILE = File.join(CONFIG_DIR, "tokens.yml")

    def self.resolve(account_slug = nil)
      if ENV["FIZZY_TOKEN"]
        raise AuthError, "--account required with FIZZY_TOKEN" unless account_slug

        return { "access_token" => ENV["FIZZY_TOKEN"], "account_slug" => normalize_slug(account_slug) }
      end

      resolve_from_file(account_slug)
    end

    def self.normalize_slug(slug)
      slug&.delete_prefix("/")
    end

    def self.token_data
      unless File.exist?(TOKEN_FILE)
        raise AuthError,
              "No tokens file at #{TOKEN_FILE}. Run: fizzy auth login --token TOKEN"
      end

      YAML.safe_load_file(TOKEN_FILE, permitted_classes: [Time])
    end

    def self.resolve_from_file(account_slug)
      data = token_data
      slug = normalize_slug(account_slug || data["default_account"])
      account = data["accounts"]&.find { |a| normalize_slug(a["account_slug"]) == slug }
      raise AuthError, "No account found for #{slug}" unless account

      account
    end
    private_class_method :resolve_from_file
  end
end
