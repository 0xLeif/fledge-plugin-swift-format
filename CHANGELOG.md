# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.2.0] - 2026-04-25

### Changed
- `.swift-format.json`: disable `UseTripleSlashForDocumentationComments` so `/** ... */` block doc comments are preserved (0xLeif uses `///` for short docs and `/** */` for longer 3+ line docs)
- `.swift-format.json`: enable `lineBreakBeforeEachArgument` so partially-split argument lists become one-arg-per-line

### Added
- 104 integration tests in `BundledConfigFormatTests` and `BundledConfigLintTests` that pipe horrible Swift code through the real `swift-format` binary and verify the bundled config produces the expected 0xLeif-style output (or reports the expected lint warning)
- `SwiftFormatRunner` test helper plus `assertFormatted`, `assertLintFinding`, `assertNoLintFinding` utilities
- Tests for whole-declaration-on-one-line explosion (struct/enum/function bodies crammed onto a single line via `;` are expanded into multi-line layout)
- Internal `Plugin.bundledConfigPath` accessor for tests to locate the bundled `.swift-format.json`

### Fixed
- `Plugin.swift` and `ProtocolHandler.swift` reformatted with the bundled config so the project dogfoods its own style

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
