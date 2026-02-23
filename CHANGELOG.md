# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [0.6.0] - 2026-02-23

### Added
- Custom URL support for self-hosted Fizzy instances
- `fizzy auth login --url URL` stores instance URL per-account in tokens.yml
- `url` key in `.fizzy.yml` for per-project instance URL
- `FIZZY_URL` environment variable for instance URL override
- URL resolution priority: `FIZZY_URL` env > `.fizzy.yml` > tokens.yml per-account > default
- URL validation in Client rejects non-http(s) URLs with clear error message
- `auth status` displays URL when using a non-default instance
- HTTP scheme detection for SSL (supports `http://` for local development)

## [0.5.0] - 2026-02-22

### Added
- Cache boards in `.fizzy.yml` as `boards: { id: name }` hash for quick lookups without API calls
- `fizzy boards sync` command to refresh the cached boards list from the API
- `fizzy init` now automatically fetches and caches all boards during setup
- `ProjectConfig#boards` accessor for reading cached board data

## [0.4.1] - 2026-02-22

### Fixed
- Card create and update sent `body` instead of `description`, causing API 400 errors (field silently dropped by Rails strong params)
- Card create with `--column` now triages via separate API call instead of sending unpermitted `column_id` param
- HTTP 400 responses now get parsed error messages (like 422) instead of raw JSON dump
- Cards, steps, and users update commands validate at least one option is provided before sending empty request

### Added
- `BadRequestError` class for explicit HTTP 400 handling

## [0.4.0] - 2026-02-22

### Added
- Per-project `.fizzy.yml` config file for account and board defaults
- `fizzy init` interactive command to create `.fizzy.yml`
- `ProjectConfig` class that walks up directories to find nearest `.fizzy.yml`
- Resolution priority: CLI flag > `.fizzy.yml` > global tokens.yml default
- `Auth.token_data` class method to centralize token file reading
- `--board` is now optional for columns and card create when set in `.fizzy.yml`

### Fixed
- Client follows Location header on any 2xx with empty body, not just 201
- All update commands handle nil response body instead of crashing with NoMethodError
- Skill file incorrectly documented `fizzy identity` instead of `fizzy auth identity`
- Guard against empty string in `--board` and `--account` flag values
- `ProjectConfig` rescues `Psych::SyntaxError` with user-friendly error message
- Blank or non-hash `.fizzy.yml` files treated as empty config instead of crashing

## [0.3.2] - 2026-02-22

### Changed
- Moved AI Agent Skill section in README to immediately follow Install

## [0.3.1] - 2026-02-22

### Changed
- Client auto-prepends account slug to API paths; CLI subcommands pass relative paths instead of manually building `/slug/resource` strings
- Removed `slug` helper from CLI::Base and `account_slug` accessor from Client

## [0.3.0] - 2026-02-22

### Added
- `fizzy skill install` command to install AI skill files for Claude Code and Codex
- `fizzy skill uninstall` command to remove installed skill files
- `--target` option (claude, codex, all) and `--scope` option (user, project)

## [0.2.2] - 2026-02-21

### Fixed
- Auth login output displays account slugs from normalized stored data instead of raw API response

## [0.2.1] - 2026-02-21

### Fixed
- Normalize account slugs at storage time during login (strip leading `/` from API response)

## [0.2.0] - 2026-02-21

### Changed
- Token storage migrated from JSON (`tokens.json`) to YAML (`tokens.yml`)
- Auth file parsing uses `YAML.safe_load_file` instead of `JSON.parse`

### Fixed
- Formatter table column alignment with CJK characters, emoji, and other wide Unicode
- Formatter handles nil cell values without error
- ValidationError now shows human-readable output (`- field: message`) instead of raw JSON
- `identity` command documented as `fizzy auth identity` in README
- HTTP connection auto-closes on process exit via `at_exit` hook

### Added
- `--account SLUG` usage example in README
- CLI integration tests for boards, cards, auth, and error handling (10 tests)

### Removed
- Unused `patch` HTTP method from Client

## [0.1.0] - 2025-02-21

### Added
- Initial release
- Board, card, column, step, comment, reaction, tag, user, notification, and pin management
- Thor-based CLI with subcommands
- Token auth with multi-account support (`--account`)
- JSON output mode (`--json`) for all commands
- Link-header pagination support
- Table, detail, and JSON output formatters
