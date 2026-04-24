---
module: format
version: 1
status: draft
files:
  - Sources/FledgeSwiftFormat/FormatCommand.swift
  - Sources/FledgeSwiftFormat/Plugin.swift
depends_on: []
---

# Format

## Purpose

Format Swift source files in-place using Apple's swift-format with the CorvidLabs style configuration. Provides both standalone CLI usage and Fledge protocol integration.

## Public API

### Exported Types

| Type | Description |
|------|-------------|
| `FormatCommand` | Executes swift-format in formatting mode |

### Exported Functions

| Function | Parameters | Returns | Description |
|----------|-----------|---------|-------------|
| `FormatCommand.init` | `(processRunner: ProcessRunner)` | `FormatCommand` | Creates a format command with the given process runner |
| `FormatCommand.run` | `(paths: [String], configPath: String)` | `Void` | Runs swift-format --in-place on the given paths |

## Invariants

1. FormatCommand always runs `swift-format format --in-place --recursive --parallel`
2. The bundled `.swift-format.json` is used unless `--use-project-config` is passed
3. All discovered `.swift` files are formatted, excluding `.build/`, `DerivedData/`, `.git/`, `.github/`, `docs/`, and `specs/`
4. Formatting modifies files in-place with no backup
5. The process exits with code 0 on success, non-zero on failure

## Behavioral Examples

### Format all Swift files in a project

```
$ fledge swift-format
  Discovering Swift files
  Running swift-format
  Done
  Swift files formatted successfully.
```

### Format specific files

```
$ fledge swift-format Sources/main.swift Tests/main.swift
  Swift files formatted successfully.
```

### Using bundled CorvidLabs config

```
$ fledge swift-format
  # Uses Sources/FledgeSwiftFormat/Resources/.swift-format.json
  # 4 spaces, 120 chars, no force unwrap, etc.
```

### Using project config

```
$ fledge swift-format --use-project-config
  # Uses ./.swift-format or ./.swift-format.json from project root
```

## Error Cases

| Condition | Behavior |
|-----------|----------|
| No Swift files found | Exit code 3 with "No Swift files found" message |
| swift-format not installed | Exit code 2 with installation hint |
| Parse error in Swift file | Exit code 1 with diagnostic from swift-format |
| Missing bundled config | Exit code 1 with "Bundled configuration is missing" |

## Dependencies

- `ProcessRunner` protocol for testable process execution
- `PluginError` for error reporting
- Apple's swift-format command-line tool

## Change Log

| Version | Date | Changes |
|---------|------|---------|
| 1 | 2026-04-23 | Initial spec |
