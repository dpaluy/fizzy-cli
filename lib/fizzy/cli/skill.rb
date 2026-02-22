# frozen_string_literal: true

require "net/http"
require "fileutils"

module Fizzy
  class CLI < Thor
    class Skill < Thor
      namespace "skill"

      SKILL_URL = "https://raw.githubusercontent.com/dpaluy/fizzy-cli/master/skills/fizzy-cli/SKILL.md"

      TARGET_PATHS = {
        "claude" => {
          "user" => File.join(Dir.home, ".claude", "skills", "fizzy-cli"),
          "project" => File.join(".claude", "skills", "fizzy-cli")
        },
        "codex" => {
          "user" => File.join(Dir.home, ".agents", "skills", "fizzy-cli"),
          "project" => File.join(".agents", "skills", "fizzy-cli")
        }
      }.freeze

      desc "install", "Install AI skill file for fizzy-cli"
      option :target, type: :string, default: "claude", enum: %w[claude codex all], desc: "Target agent"
      option :scope, type: :string, default: "user", enum: %w[user project], desc: "Install scope"
      def install
        content = fetch_skill

        targets_for(options[:target]).each do |target|
          dir = TARGET_PATHS.dig(target, options[:scope])
          path = File.join(dir, "SKILL.md")

          if File.exist?(path) && File.read(path) == content
            say "Already up to date: #{path}"
          else
            verb = File.exist?(path) ? "Updated" : "Installed"
            FileUtils.mkdir_p(dir)
            File.write(path, content)
            say "#{verb}: #{path}"
          end
        end
      end

      desc "uninstall", "Remove AI skill file for fizzy-cli"
      option :target, type: :string, default: "claude", enum: %w[claude codex all], desc: "Target agent"
      option :scope, type: :string, default: "user", enum: %w[user project], desc: "Install scope"
      def uninstall
        targets_for(options[:target]).each do |target|
          dir = TARGET_PATHS.dig(target, options[:scope])

          unless File.directory?(dir)
            say "Not installed: #{dir}"
            next
          end

          FileUtils.rm_rf(dir)
          say "Removed: #{dir}"
        end
      end

      def self.exit_on_failure? = true

      private

      def targets_for(target)
        target == "all" ? %w[claude codex] : [target]
      end

      def fetch_skill
        uri = URI(SKILL_URL)
        response = Net::HTTP.get_response(uri)

        raise Thor::Error, "Failed to fetch skill file (HTTP #{response.code})" unless response.is_a?(Net::HTTPSuccess)

        response.body.force_encoding("UTF-8")
      rescue SocketError, Errno::ECONNREFUSED, Net::OpenTimeout, Net::ReadTimeout => e
        raise Thor::Error, "Could not fetch skill file: #{e.message}"
      end
    end
  end
end
