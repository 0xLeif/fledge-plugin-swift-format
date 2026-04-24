# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2026-04-23

### Added
- Initial release of `fledge-plugin-swift-format`
- `fledge swift-format` command for in-place formatting
- `fledge swift-format --lint` for linting without modifying
- `fledge swift-format --check` for strict CI lint mode
- Bundled CorvidLabs `.swift-format.json` configuration
- `--use-project-config` flag to opt out of bundled config
- Fledge v1 protocol support with progress, log, and output messages
- File discovery excluding `.build/`, `DerivedData/`, `.git/`, etc.
- Unit tests for argument parsing, FormatCommand, and LintCommand
- spec-sync specs for `format` and `lint` modules
- GitHub Actions CI workflow
