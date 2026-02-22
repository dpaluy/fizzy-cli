# frozen_string_literal: true

require_relative "lib/fizzy/version"

Gem::Specification.new do |spec|
  spec.name = "fizzy-cli"
  spec.version = Fizzy::VERSION
  spec.authors = ["David Paluy"]
  spec.email = ["dpaluy@gmail.com"]

  spec.summary = "CLI for Fizzy project management"
  spec.description = "Command-line client for Fizzy project management. " \
                     "Manage boards, cards, columns, steps, comments, and more from the terminal."
  spec.homepage = "https://github.com/dpaluy/fizzy-cli"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2"

  spec.metadata["rubygems_mfa_required"] = "true"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/dpaluy/fizzy-cli"
  spec.metadata["changelog_uri"] = "https://github.com/dpaluy/fizzy-cli/blob/master/CHANGELOG.md"
  spec.metadata["bug_tracker_uri"] = "https://github.com/dpaluy/fizzy-cli/issues"

  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[test/ Gemfile .gitignore .github/ .rubocop.yml docs/ .agents/ AGENTS.md CLAUDE.md
                          Rakefile .yardopts skills/]) ||
        f.end_with?(".png", ".jpg", ".gif")
    end
  end
  spec.extra_rdoc_files = Dir["README.md", "CHANGELOG.md", "LICENSE.txt"]
  spec.bindir = "bin"
  spec.executables = ["fizzy"]

  spec.add_dependency "thor", "~> 1.5"
end
