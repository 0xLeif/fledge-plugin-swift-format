# fledge-plugin-swift-format

[![CI](https://github.com/0xLeif/fledge-plugin-swift-format/actions/workflows/ci.yml/badge.svg)](https://github.com/0xLeif/fledge-plugin-swift-format/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

A [Fledge](https://github.com/CorvidLabs/fledge) plugin that formats and lints Swift code with the CorvidLabs style guide.

## Install

```bash
fledge plugins install 0xLeif/fledge-plugin-swift-format
```

## Usage

### Format all Swift files

```bash
fledge swift-format
```

### Lint without modifying

```bash
fledge swift-format --lint
```

### Strict lint for CI

```bash
fledge swift-format --check
```

### Use your own config

```bash
fledge swift-format --use-project-config
```

### Format specific paths

```bash
fledge swift-format Sources/MyModule Tests/MyModuleTests
```

## CorvidLabs Style

This plugin ships a locked configuration that enforces:

- **4 spaces** indentation
- **120 character** line length
- **K&R braces** (opening brace on same line)
- **No force unwrap** (`!`) or force try (`try!`)
- **No semicolons**
- **Ordered imports**
- **Triple-slash** documentation comments
- And more...

See the full config in `Sources/FledgeSwiftFormat/Resources/.swift-format.json`.

## Standalone Usage

The binary also works outside Fledge:

```bash
swift build -c release
.build/release/fledge-plugin-swift-format --lint
```

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | Lint violations found (strict mode) or format error |
| 2 | swift-format not installed |
| 3 | No Swift files found |

## Development

```bash
swift build
swift test
swift-format lint --strict -r Sources Tests
```

## License

MIT
