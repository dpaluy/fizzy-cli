# Fizzy CLI

Ruby gem — command-line client for [Fizzy](https://fizzy.do) project management.

Ask more questions until you have enough context to give an accurate & confident answer.

## WHAT (Architecture)

- **Ruby 4.0.1** gem with **Thor 1.5** CLI framework
- Production gem, MIT licensed
- HTTP client talking to `https://app.fizzy.do` REST API
- Token auth stored at `~/.config/fizzy-cli/tokens.yml`

### Structure

```
bin/fizzy              # Entry point
lib/fizzy.rb           # Requires all modules
lib/fizzy/
  cli.rb               # Root Thor CLI with subcommands
  cli/base.rb           # Shared module (client, auth, output helpers)
  cli/boards.rb         # Board CRUD
  cli/cards.rb           # Card CRUD + actions (close, triage, tag, assign, etc.)
  cli/columns.rb         # Column CRUD (board-scoped)
  cli/steps.rb           # Step CRUD (card-scoped)
  cli/comments.rb        # Comment CRUD (card-scoped)
  cli/reactions.rb       # Reaction CRUD
  cli/tags.rb            # Tag listing
  cli/users.rb           # User management
  cli/notifications.rb   # Notification management
  cli/pins.rb            # Pin/unpin cards
  cli/auth.rb            # Auth subcommands (login, status, switch)
  auth.rb               # Token resolution (file + env var)
  project_config.rb     # .fizzy.yml resolution (walks up from pwd)
  client.rb             # HTTP client (Net::HTTP, JSON, bearer auth)
  paginator.rb          # Link-header pagination
  formatter.rb          # Output: table, json, detail
  errors.rb             # Error hierarchy
  version.rb            # VERSION constant
skills/fizzy-cli/       # Claude Code skill for using the CLI
```

## WHY (Purpose)

CLI for managing Fizzy boards, cards, columns, steps, comments, reactions, tags, users, notifications, and pins. All commands support `--json` for machine output and `--account SLUG` for multi-account targeting.

### Key Concepts

- **Cards** are addressed by **number** (integer), everything else by **ID** (base36 UUID)
- **Columns** and **Steps** are scoped (`--board` / `--card`, or board from `.fizzy.yml`)
- `Client` uses `Net::HTTP` directly, returns `Fizzy::Response` (Data.define). Auto-prepends `/{account_slug}/` to relative paths; absolute paths (starting with `/`) pass through as-is
- `Paginator` follows RFC 5988 Link headers for pagination
- CLI subcommands pass relative paths (e.g. `"cards/#{number}"`) — the Client handles slug prefixing
- All CLI subcommands include `Base` module for shared `client`, `account`, `board`, `require_board!`, `json?`, `output_list`, `output_detail`
- `ProjectConfig` finds `.fizzy.yml` by walking up from `Dir.pwd` — provides `account` and `board` defaults
- Resolution priority: CLI flag > `.fizzy.yml` > global default from tokens.yml

## HOW (Workflows)

### Build & Install

```sh
gem build fizzy-cli.gemspec
gem install fizzy-cli-0.1.0.gem
```

### Development

```sh
bundle install
ruby -Ilib bin/fizzy help
```

### Testing

```sh
bundle exec rake          # tests + rubocop
bundle exec rake test     # tests only
```

### Adding a New Subcommand

1. Create `lib/fizzy/cli/resource.rb` — Thor subclass including `Base`
2. Add `require_relative` in `lib/fizzy/cli.rb`
3. Register with `subcommand` in `Fizzy::CLI`
4. Follow existing patterns: `output_list`/`output_detail` for display, `paginator.all` for lists

### Code Style

- Ruby 4.0.1 features allowed (Data.define, pattern matching, etc.)
- Snake_case methods, `frozen_string_literal: true` included by convention (not required in Ruby 4)
- Minimal dependencies — stdlib `net/http`, `json`, `uri` only
- Thor conventions for CLI option declarations
