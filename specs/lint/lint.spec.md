---
module: lint
version: 1
status: draft
files:
  - Sources/FledgeSwiftFormat/LintCommand.swift
  - Sources/FledgeSwiftFormat/Plugin.swift
depends_on: []
---

# Lint

## Purpose

Diagnose style issues in Swift source code using Apple's swift-format with the CorvidLabs style configuration. Runs in lint mode (no file modification) with optional strict mode for CI integration.

## Public API

### Exported Types

| Type | Description |
|------|-------------|
| `LintCommand` | Executes swift-format in lint mode |

### Exported Functions

| Function | Parameters | Returns | Description |
|----------|-----------|---------|-------------|
| `LintCommand.init` | `(processRunner: ProcessRunner)` | `LintCommand` | Creates a lint command with the given process runner |
| `LintCommand.run` | `(paths: [String], configPath: String, strict: Bool)` | `Void` | Runs swift-format lint on the given paths |

## Invariants

1. LintCommand always runs `swift-format lint --recursive --parallel`
2. `--strict` mode treats all findings as errors and exits non-zero
3. Non-strict mode prints findings to stdout but exits 0 unless parsing fails
4. The bundled `.swift-format.json` is used unless `--use-project-config` is passed
5. File discovery exclusions match the format command exactly

## Behavioral Examples

### Lint all Swift files

```
$ fledge swift-format --lint
  Discovering Swift files
  Running swift-format
  /project/Sources/main.swift:42:1: warning: [DoNotUseSemicolons] remove semicolon
  Done
```

### Strict lint for CI

```
$ fledge swift-format --check
  /project/Sources/main.swift:42:1: error: [DoNotUseSemicolons] remove semicolon
  Error: swift-format exited with code 1
```

### Lint specific paths

```
$ fledge swift-format --lint Sources/Tests
  [diagnostics for files in Sources/Tests only]
```

## Error Cases

| Condition | Behavior |
|-----------|----------|
| No Swift files found | Exit code 3 with "No Swift files found" message |
| swift-format not installed | Exit code 2 with installation hint |
| Style violations in strict mode | Exit code 1 with violation list |
| Parse error in Swift file | Exit code 1 with diagnostic from swift-format |

## Dependencies

- `ProcessRunner` protocol for testable process execution
- `PluginError` for error reporting
- Apple's swift-format command-line tool

## Change Log

| Version | Date | Changes |
|---------|------|---------|
| 1 | 2026-04-23 | Initial spec |
