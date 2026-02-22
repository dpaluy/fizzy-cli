# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project adheres to [Semantic Versioning](https://semver.org/).

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
